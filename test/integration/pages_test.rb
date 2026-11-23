require "test_helper"

# Every page renders, through the HTML flow a browser takes. The model tests
# never render a view, so a broken path helper shipped as a 500 on / (2026-11-23).
class PagesTest < ActionDispatch::IntegrationTest
  setup do
    @dog = Pet.create!(sku: "T-DOG", name: "Rex", species: "dog", price_cents: 10_000, stock: 2)
  end

  test "browse, add, change, remove, check out" do
    get root_path
    assert_response :success
    assert_select "form[action=?]", "/cart/items"

    get pet_path(@dog.sku)
    assert_response :success

    post "/cart/items", params: { sku: @dog.sku }
    assert_redirected_to cart_path
    follow_redirect!
    assert_response :success
    assert_select "form[action=?]", "/cart/items/#{@dog.sku}"

    patch "/cart/items/#{@dog.sku}", params: { quantity: 2 }
    follow_redirect!
    assert_response :success

    post "/checkout", params: { idempotency_key: "k-1" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal 0, @dog.reload.stock
  end

  test "removing a line leaves an empty cart page" do
    post "/cart/items", params: { sku: @dog.sku }
    delete "/cart/items/#{@dog.sku}"
    follow_redirect!
    assert_response :success
    assert_select "p.empty"
  end
end
