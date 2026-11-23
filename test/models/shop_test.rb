require "test_helper"

class ShopTest < ActiveSupport::TestCase
  setup do
    @dog = Pet.create!(sku: "T-DOG", name: "Rex", species: "dog", price_cents: 10_000, stock: 2)
    @fish = Pet.create!(sku: "T-FSH", name: "Nemo", species: "fish", price_cents: 250, stock: 5)
    @cart = Cart.create!(token: "t-1")
  end

  test "the total is the sum of the line items" do
    @cart.add(@dog, 2)
    @cart.add(@fish, 3)
    assert_equal 2 * 10_000 + 3 * 250, @cart.total_cents
    assert_equal 5, @cart.item_count
  end

  test "adding beyond the stock is refused and changes nothing" do
    @cart.add(@dog, 2)
    assert_raises(Cart::OutOfStock) { @cart.add(@dog, 1) }
    assert_equal 2, @cart.items.find_by(pet: @dog).quantity
  end

  test "setting a quantity to zero removes the line" do
    @cart.add(@fish, 3)
    @cart.set_quantity(@fish, 0)
    assert @cart.empty?
  end

  test "checkout takes stock, empties the cart and is idempotent per key" do
    @cart.add(@dog, 1)
    order, created = Order.place!(@cart, "key-1")
    assert created
    assert_equal 10_000, order.total_cents
    assert_equal 1, @dog.reload.stock
    assert @cart.reload.empty?

    again, created_again = Order.place!(@cart, "key-1")
    assert_not created_again
    assert_equal order, again
    assert_equal 1, @dog.reload.stock
  end

  test "checkout of an empty cart is refused" do
    assert_raises(Order::EmptyCart) { Order.place!(@cart, "key-2") }
  end

  test "the database refuses negative stock even past the model" do
    assert_raises(ActiveRecord::StatementInvalid) { @dog.update_columns(stock: -1) }
  end
end
