require "test_helper"

# Who placed order N: the order row records the driver and trace at placement,
# and the checkout's server span names the driver, the run and the order.
class OrderAttributionTest < ActionDispatch::IntegrationTest
  include TelemetryHelpers

  setup do
    @dog = Pet.create!(sku: "T-DOG", name: "Rex", species: "dog", price_cents: 10_000, stock: 2)
  end

  test "an order placed by a named runner records its driver and trace id" do
    post "/cart/items", params: { sku: @dog.sku }
    post "/checkout", params: { idempotency_key: "attr-1" },
                      headers: { "baggage" => "app.driver=webmcp,app.run=devtools-ai-1" }
    order = Order.find_by!(idempotency_key: "attr-1")
    assert_equal "webmcp", order.driver
    assert_equal response_trace_id, order.trace_id

    checkout = server_spans.find { _1.dig("attributes", "url.path") == "/checkout" }
    assert_equal order.trace_id, checkout["trace_id"]
    assert_equal "webmcp", checkout.dig("attributes", "app.driver")
    assert_equal "devtools-ai-1", checkout.dig("attributes", "app.run")
    assert_equal order.id, checkout.dig("attributes", "app.order.id")
  end

  test "a page with ?ff= on its URL names the runner for its checkout" do
    post "/cart/items?ff=driver:agent,run:x", params: { sku: @dog.sku }
    post "/checkout?ff=driver:agent,run:x", params: { idempotency_key: "attr-2" }
    order = Order.find_by!(idempotency_key: "attr-2")
    assert_equal "agent", order.driver
  end

  test "an unnamed runner is recorded as unknown, and a retry keeps the first placement" do
    post "/cart/items", params: { sku: @dog.sku }
    post "/checkout", params: { idempotency_key: "attr-3" }
    first = Order.find_by!(idempotency_key: "attr-3")
    assert_equal "unknown", first.driver

    post "/checkout", params: { idempotency_key: "attr-3" }, headers: { "baggage" => "app.driver=curl" }
    assert_equal "unknown", first.reload.driver, "a repeat returns the order; it does not re-attribute it"
  end

  test "the JSON order says who placed it" do
    post "/cart/items", params: { sku: @dog.sku }
    post "/checkout", params: { idempotency_key: "attr-4" }.to_json,
                      headers: { "Content-Type" => "application/json", "Accept" => "application/json",
                                 "baggage" => "app.driver=curl" }
    body = JSON.parse(response.body)
    assert_equal "curl", body["driver"]
    assert_equal response_trace_id, body["trace_id"]
  end

  test "orders placed outside a request have no attribution" do
    cart = Cart.create!(token: "t-x")
    cart.add(@dog, 1)
    order, = Order.place!(cart, "attr-5")
    assert_nil order.driver
    assert_nil order.trace_id
  end
end
