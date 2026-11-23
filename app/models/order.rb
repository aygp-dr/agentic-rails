# Checkout is the one consequential action: it takes stock and empties the
# cart. An idempotency key makes a repeated checkout return the first order
# instead of placing a second one.
class Order < ApplicationRecord
  class EmptyCart < StandardError; end

  belongs_to :cart

  validates :idempotency_key, presence: true, uniqueness: true
  validates :total_cents, numericality: { only_integer: true, greater_than: 0 }

  def self.place!(cart, idempotency_key)
    existing = find_by(idempotency_key: idempotency_key)
    return [existing, false] if existing

    transaction do
      raise EmptyCart, "the cart is empty" if cart.empty?
      cart.items.includes(:pet).each do |item|
        pet = item.pet.lock!
        raise Cart::OutOfStock, "#{pet.name}: only #{pet.stock} in stock" if item.quantity > pet.stock
        pet.update!(stock: pet.stock - item.quantity)
      end
      order = create!(cart: cart, total_cents: cart.total_cents, item_count: cart.item_count,
                      idempotency_key: idempotency_key, status: "placed")
      cart.items.destroy_all
      [order, true]
    end
  end

  def total = format("$%.2f", total_cents / 100.0)
end
