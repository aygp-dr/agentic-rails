ENV["RAILS_ENV"] ||= "test"
# Telemetry is on in every environment, so the suite gets its own state dir:
# nothing a test does reaches the owner's ~/.local/state/agentic-rails (C9).
require "tmpdir"
ENV["XDG_STATE_HOME"] = Dir.mktmpdir("agentic-rails-test-state")
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1) # one SQLite file; the suite is small


    # Add more helper methods to be used by all tests here...
  end
end

# A fresh data dir per test, and the spans written to it.
module TelemetryHelpers
  def self.included(base)
    base.setup do
      @previous_data_dir = Telemetry.data_dir
      Telemetry.data_dir = Dir.mktmpdir("telemetry")
    end
    base.teardown { Telemetry.data_dir = @previous_data_dir }
  end

  def traces_path = File.join(Telemetry.data_dir, "traces.jsonl")

  def spans
    return [] unless File.exist?(traces_path)
    File.readlines(traces_path, chomp: true).map { JSON.parse(_1) }
  end

  def server_spans = spans.select { _1["kind"] == "server" }

  def response_traceparent = response.headers["traceparent"]
  def response_trace_id = response_traceparent&.split("-")&.at(1)
end
