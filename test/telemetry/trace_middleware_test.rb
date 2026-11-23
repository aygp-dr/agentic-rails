require "test_helper"

# slot.org T1-T5, T7, T8, T11: the request's server span, through the whole app.
class TraceMiddlewareTest < ActionDispatch::IntegrationTest
  include TelemetryHelpers

  TRACE = "4bf92f3577b34da6a3ce929d0e0e4736"
  PARENT = "00f067aa0ba902b7"
  HEX32 = /\A[0-9a-f]{32}\z/
  HEX16 = /\A[0-9a-f]{16}\z/

  setup do
    Pet.create!(sku: "T-DOG", name: "Rex", species: "dog", price_cents: 10_000, stock: 2)
  end

  test "continues a valid traceparent and echoes it (T1, T2)" do
    get "/pets.json", headers: { "traceparent" => "00-#{TRACE}-#{PARENT}-01" }
    assert_response :success
    assert_match(/\A00-#{TRACE}-[0-9a-f]{16}-01\z/, response_traceparent)
    server = server_spans.sole
    assert_equal TRACE, server["trace_id"]
    assert_equal PARENT, server["parent_span_id"]
    assert_equal response_traceparent.split("-")[2], server["span_id"]
  end

  test "starts a trace when traceparent is absent or malformed (T1)" do
    ["", "00-zz-not-a-trace", "00-#{"0" * 32}-#{PARENT}-01", "00-#{TRACE}-#{"0" * 16}-01",
     "00-#{TRACE.upcase}-#{PARENT}-01", "ff-#{TRACE}-#{PARENT}-01"].each do |bad|
      get "/pets.json", headers: { "traceparent" => bad }
      assert_match HEX32, response_trace_id, bad
      assert_not_equal TRACE, response_trace_id, bad
    end
    roots = server_spans
    assert_equal 6, roots.size
    roots.each { assert_nil _1["parent_span_id"] }
    assert_equal 6, roots.map { _1["trace_id"] }.uniq.size
  end

  test "every response carries a traceparent, errors and 404s included (T2)" do
    get "/pets/NO-SUCH-PET.json"
    assert_response :not_found
    assert_match HEX32, response_trace_id
    assert_equal 404, server_spans.sole["attributes"]["http.response.status_code"]
  end

  test "a server span has the OTLP-flattened fields and the HTTP attributes (T7, T8)" do
    get "/pets/T-DOG.json?secret=query"
    span = server_spans.sole
    assert_match HEX32, span["trace_id"]
    assert_match HEX16, span["span_id"]
    assert_equal "server", span["kind"]
    assert_equal "GET /pets/:id", span["name"]
    assert_kind_of Integer, span["start_time_unix_nano"]
    assert_operator span["end_time_unix_nano"], :>=, span["start_time_unix_nano"]
    assert_equal "agentic-rails", span.dig("resource", "service.name")
    assert_includes %w[OK UNSET], span.dig("status", "code")
    attributes = span["attributes"]
    assert_equal "GET", attributes["http.request.method"]
    assert_equal "/pets/T-DOG.json", attributes["url.path"]
    assert_equal "/pets/:id", attributes["http.route"]
    assert_equal 200, attributes["http.response.status_code"]
    assert_equal "unknown", attributes["app.driver"]
    assert_not_includes File.read(traces_path), "secret", "the query string is never recorded"
  end

  test "baggage names the runner (T3, T8)" do
    get "/", headers: { "baggage" => "app.driver=playwright, app.run=pw-17639,gen_ai.agent.name=claude-code;p=1,gen_ai.agent.id=s-42" }
    attributes = server_spans.sole["attributes"]
    assert_equal "playwright", attributes["app.driver"]
    assert_equal "pw-17639", attributes["app.run"]
    assert_equal "claude-code", attributes["gen_ai.agent.name"]
    assert_equal "s-42", attributes["gen_ai.agent.id"]
  end

  test "invalid values are dropped and the driver list is closed (T3, T4)" do
    get "/", headers: { "baggage" => "app.driver=robot,app.run=Has_Caps,gen_ai.agent.name=#{"a" * 49},gen_ai.agent.id=" }
    attributes = server_spans.last["attributes"]
    assert_equal "unknown", attributes["app.driver"]
    %w[app.run gen_ai.agent.name gen_ai.agent.id].each { assert_not attributes.key?(_1), "#{_1} should be absent" }

    get "/", headers: { "baggage" => "app.driver=Not_Valid,app.run=#{"r" * 48}" }
    attributes = server_spans.last["attributes"]
    assert_equal "unknown", attributes["app.driver"]
    assert_equal "r" * 48, attributes["app.run"]
  end

  test "percent-encoded baggage values are decoded before validation (T3)" do
    get "/", headers: { "baggage" => "app.driver=%63url,app.run=a%2Fb" }
    attributes = server_spans.sole["attributes"]
    assert_equal "curl", attributes["app.driver"]
    assert_not attributes.key?("app.run"), "a/b is outside [a-z0-9-]"
  end

  test "the server reads ?ff= on the request, baggage wins key by key (T5)" do
    get "/?ff=driver:agent,run:x-1,agent:claude,agent-id:i-9,cart-v2:on"
    attributes = server_spans.last["attributes"]
    assert_equal "agent", attributes["app.driver"]
    assert_equal "x-1", attributes["app.run"]
    assert_equal "claude", attributes["gen_ai.agent.name"]
    assert_equal "i-9", attributes["gen_ai.agent.id"]

    get "/?ff=driver:agent,run:x-1", headers: { "baggage" => "app.run=from-baggage" }
    attributes = server_spans.last["attributes"]
    assert_equal "agent", attributes["app.driver"]
    assert_equal "from-baggage", attributes["app.run"]

    get "/?ff=driver:robot,run:BAD"
    attributes = server_spans.last["attributes"]
    assert_equal "unknown", attributes["app.driver"]
    assert_not attributes.key?("app.run")
  end

  test "one trace has one driver, database spans included (T11)" do
    get "/pets.json", headers: { "baggage" => "app.driver=curl" }
    drivers = spans.map { _1.dig("attributes", "app.driver") }.uniq
    assert_equal ["curl"], drivers
    assert_operator spans.size, :>, 1, "expected database spans too"
  end

  test "spans from concurrent requests are whole lines" do
    app = Telemetry::Middleware.new(->(_env) { [200, {}, ["ok"]] })
    threads = 8.times.map do
      Thread.new { 25.times { app.call(Rack::MockRequest.env_for("/")) } }
    end
    threads.each(&:join)
    lines = File.readlines(traces_path)
    assert_equal 200, lines.size
    lines.each { JSON.parse(_1) }
  end
end

# T8 for errors, on the middleware alone: an app that answers 503, and one that raises.
class TraceMiddlewareErrorTest < ActiveSupport::TestCase
  include TelemetryHelpers

  test "a 5xx sets status ERROR; below 500 is not ERROR (T8)" do
    Telemetry::Middleware.new(->(_env) { [503, {}, []] }).call(Rack::MockRequest.env_for("/x"))
    Telemetry::Middleware.new(->(_env) { [422, {}, []] }).call(Rack::MockRequest.env_for("/y"))
    error, client_error = server_spans
    assert_equal "ERROR", error.dig("status", "code")
    assert_equal 503, error.dig("attributes", "http.response.status_code")
    assert_not_equal "ERROR", client_error.dig("status", "code")
  end

  test "an exception is recorded as a 500 and re-raised" do
    app = Telemetry::Middleware.new(->(_env) { raise ArgumentError, "boom" })
    assert_raises(ArgumentError) { app.call(Rack::MockRequest.env_for("/z")) }
    span = server_spans.sole
    assert_equal "ERROR", span.dig("status", "code")
    assert_equal 500, span.dig("attributes", "http.response.status_code")
    assert_nil Telemetry.current, "the context does not leak past the request"
  end

  test "the data dir defaults to $XDG_STATE_HOME/agentic-rails" do
    Telemetry.data_dir = nil
    assert_equal File.join(ENV.fetch("XDG_STATE_HOME"), "agentic-rails"), Telemetry.data_dir
    assert_not_equal File.expand_path("~/.local/state/agentic-rails"), Telemetry.data_dir
  end
end
