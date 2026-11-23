require "test_helper"

# The JSON calls app/javascript/webmcp.js makes, exactly as it makes them
# (JSON body, Accept: application/json), so a tool can't drift from its endpoint.
class WebmcpContractTest < ActionDispatch::IntegrationTest
  JSON_HEADERS = { "Accept" => "application/json", "Content-Type" => "application/json" }.freeze

  setup do
    @dog = Pet.create!(sku: "T-DOG", name: "Rex", species: "dog", price_cents: 10_000, stock: 2)
  end

  def json(verb, path, body = nil)
    send(verb, path, params: body&.to_json, headers: JSON_HEADERS)
    JSON.parse(response.body)
  end

  test "search, add, refuse past stock, update, read, check out once" do
    assert_includes json(:get, "/pets.json").map { _1["sku"] }, "T-DOG"

    cart = json(:post, "/cart/items", { sku: "T-DOG", quantity: 2 })
    assert_response :success
    assert_equal 2, cart["item_count"]

    refused = json(:post, "/cart/items", { sku: "T-DOG", quantity: 1 })
    assert_response :unprocessable_entity
    assert refused["error"]

    assert_equal 1, json(:patch, "/cart/items/T-DOG", { quantity: 1 })["item_count"]
    assert_equal 10_000, json(:get, "/cart")["total_cents"]

    order = json(:post, "/checkout", { idempotency_key: "tool-1" })
    assert_response :created
    assert order["created"]
    again = json(:post, "/checkout", { idempotency_key: "tool-1" })
    assert_response :ok
    assert_equal order["id"], again["id"]
    assert_equal false, again["created"]
    assert_equal 1, @dog.reload.stock
  end

  test "update to zero removes the line" do
    json(:post, "/cart/items", { sku: "T-DOG" })
    assert_equal 0, json(:patch, "/cart/items/T-DOG", { quantity: 0 })["item_count"]
  end
end
