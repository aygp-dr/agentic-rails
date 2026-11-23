require "test_helper"

# The page's half of T5: its own fetches send traceparent and baggage. The
# browser runs this code, so the test pins what the source does, as
# webmcp_contract_test does for the tool calls.
class PageRunnerTest < ActionDispatch::IntegrationTest
  def source(name) = Rails.root.join("app/javascript/#{name}.js").read

  test "the layout's footer fetch and Turbo's fetches carry the trace headers" do
    get "/"
    assert_select "script[type=importmap]", text: /"telemetry"/
    assert_match(/import \{ traceHeaders \} from "telemetry"/, response.body)
    assert_match(/fetch\("\/api\/build", \{ headers: traceHeaders\(\) \}\)/, response.body)
    assert_match(/turbo:before-fetch-request/, source("telemetry"))
  end

  test "telemetry.js reads ?ff= and window.appRunner and builds W3C headers" do
    js = source("telemetry")
    assert_match(/traceparent/, js)
    assert_match(/baggage/, js)
    assert_match(/appRunner/, js)
    assert_match(/"agent-id"/, js)
  end

  test "webmcp.js names itself in a proper baggage header with a traceparent" do
    js = source("webmcp")
    assert_match(/traceHeaders\(\{ driver: "webmcp" \}\)/, js)
    assert_no_match(/baggage: "app.driver=webmcp"/, js)
  end
end
