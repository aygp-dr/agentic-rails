require "json"
require "securerandom"
require "fileutils"
require "uri"

# Spans for slot.org 0.1.1, profile trace, written by hand rather than through
# opentelemetry-ruby: the contract is a JSON-lines file with OTLP field names,
# and owning the ~200 lines that write it is cheaper than configuring an SDK
# and exporter to produce exactly that shape.
#
# One request = one Context (thread-local while the request runs). The
# middleware opens it; database statements add client spans to it; it is
# written to <data dir>/traces.jsonl when the request ends.
module Telemetry
  SERVICE = "agentic-rails"
  PREFIX = "app"
  DRIVER = "#{PREFIX}.driver"
  RUN = "#{PREFIX}.run"
  DRIVERS = %w[human agent webmcp playwright bombadil automation curl ops unknown].freeze
  VALUE = /\A[a-z0-9-]{1,48}\z/
  # baggage key and ?ff= key for each runner attribute (T3, T5)
  RUNNER_KEYS = { DRIVER => "driver", RUN => "run",
                  "gen_ai.agent.name" => "agent", "gen_ai.agent.id" => "agent-id" }.freeze

  class << self
    attr_writer :data_dir

    # $XDG_STATE_HOME/agentic-rails, read when first needed, so a test (or a
    # slot) that sets XDG_STATE_HOME gets its own.
    def data_dir
      @data_dir ||= File.join(ENV["XDG_STATE_HOME"].presence || File.expand_path("~/.local/state"), SERVICE)
    end

    def traces_path = File.join(data_dir, "traces.jsonl")

    def current = Thread.current[:telemetry_context]

    def current=(context)
      Thread.current[:telemetry_context] = context
    end

    def now_ns = Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
    def trace_id = random_hex(16)
    def span_id = random_hex(8)

    # Lines are appended under a process mutex and an flock, one write per
    # request, so concurrent requests (and processes) never interleave.
    def write(spans)
      return if spans.empty?
      text = spans.map { JSON.generate(_1) + "\n" }.join
      MUTEX.synchronize do
        FileUtils.mkdir_p(data_dir)
        File.open(traces_path, File::WRONLY | File::APPEND | File::CREAT, 0o644) do |file|
          file.flock(File::LOCK_EX)
          file.write(text)
        end
      end
    rescue SystemCallError, IOError => error
      warn "telemetry: could not write #{traces_path}: #{error.class}" # never fail the request for it
    end

    private

    def random_hex(bytes)
      loop do
        hex = SecureRandom.hex(bytes)
        return hex unless hex.match?(/\A0+\z/)
      end
    end
  end

  MUTEX = Mutex.new

  # W3C traceparent, version 00 only: anything else starts a new trace (T1).
  module Traceparent
    FORMAT = /\A00-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})\z/

    def self.parse(header)
      match = FORMAT.match(header.to_s.strip) or return nil
      trace_id, parent_id, = match.captures
      return nil if trace_id.match?(/\A0+\z/) || parent_id.match?(/\A0+\z/)
      [trace_id, parent_id]
    end

    def self.format(trace_id, span_id) = "00-#{trace_id}-#{span_id}-01"
  end

  # The runner attributes from baggage and ?ff=, validated (T3-T5). Baggage
  # wins key by key; an invalid value is dropped; the driver is always set,
  # and anything outside the closed list is unknown.
  module Runner
    def self.attributes(baggage: nil, query: nil)
      from_ff = parse_ff(query)
      from_baggage = parse_baggage(baggage)
      attributes = {}
      RUNNER_KEYS.each_key do |key|
        value = from_baggage.fetch(key) { from_ff[key] }
        attributes[key] = value if value&.match?(VALUE)
      end
      attributes[DRIVER] = "unknown" unless DRIVERS.include?(attributes[DRIVER])
      attributes
    end

    # "k=v;prop, k2=v2" -> {"k" => "v", ...}, percent-decoded, our keys only.
    def self.parse_baggage(header)
      header.to_s.split(",").each_with_object({}) do |member, found|
        key, value = member.split(";", 2).first.split("=", 2).map(&:strip)
        next unless value && RUNNER_KEYS.key?(key)
        found[key] = URI.decode_www_form_component(value) rescue nil
      end
    end

    # ?ff=driver:agent,run:x,agent:a,agent-id:i (other items are flags, ignored).
    def self.parse_ff(query)
      ff = Rack::Utils.parse_query(query.to_s)["ff"]
      ff = ff.last if ff.is_a?(Array)
      names = RUNNER_KEYS.invert
      ff.to_s.split(",").each_with_object({}) do |item, found|
        name, value = item.split(":", 2)
        key = names[name.to_s.strip]
        found[key] = value.to_s.strip if key
      end
    end
  end

  # One request's trace: its server span and the client spans under it.
  class Context
    attr_reader :trace_id, :span_id, :parent_span_id, :attributes, :spans

    def initialize(trace_id:, parent_span_id:, attributes:)
      @trace_id = trace_id
      @parent_span_id = parent_span_id
      @span_id = Telemetry.span_id
      @attributes = attributes
      @spans = []
      @start = Telemetry.now_ns
    end

    def driver = attributes[DRIVER]
    def traceparent = Traceparent.format(trace_id, span_id)
    def set_attribute(key, value) = (attributes[key] = value)

    def add_client_span(span_id:, name:, start_ns:, end_ns:, attributes:)
      spans << span(span_id: span_id, parent: self.span_id, name: name, kind: "client",
                    start_ns: start_ns, end_ns: end_ns, status: "UNSET",
                    attributes: attributes.merge(DRIVER => driver))
    end

    # The server span goes last: its children finished inside it.
    def finish(name:, status_code:)
      server = span(span_id: span_id, parent: parent_span_id, name: name, kind: "server",
                    start_ns: @start, end_ns: Telemetry.now_ns,
                    status: status_code >= 500 ? "ERROR" : "UNSET",
                    attributes: attributes.merge("http.response.status_code" => status_code))
      spans + [server]
    end

    private

    def span(span_id:, parent:, name:, kind:, start_ns:, end_ns:, status:, attributes:)
      record = { trace_id: trace_id, span_id: span_id }
      record[:parent_span_id] = parent if parent
      record.merge(name: name, kind: kind, start_time_unix_nano: start_ns, end_time_unix_nano: end_ns,
                   status: { code: status }, resource: { "service.name" => SERVICE },
                   attributes: attributes)
    end
  end
end

require_relative "middleware"
require_relative "sql"
