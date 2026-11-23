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

  test "each cart line has its own quantity field id" do
    cat = Pet.create!(sku: "T-CAT", name: "Tom", species: "cat", price_cents: 5_000, stock: 3)
    post "/cart/items", params: { sku: @dog.sku }
    post "/cart/items", params: { sku: cat.sku }
    get cart_path
    ids = css_select("input[type=number]").map { _1["id"] }
    assert_equal 2, ids.size
    assert_equal ids.uniq, ids, "duplicate ids: a selector like #quantity hits the first line only"
  end

  test "the layout declares its language, a description and an icon" do
    get root_path
    assert_select "html[lang=en]"
    assert_select "meta[name=description][content]"
    assert_select "link[rel=icon]"
  end

  test "removing a line leaves an empty cart page" do
    post "/cart/items", params: { sku: @dog.sku }
    delete "/cart/items/#{@dog.sku}"
    follow_redirect!
    assert_response :success
    assert_select "p.empty"
  end
end
