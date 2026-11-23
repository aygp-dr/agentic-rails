class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :pet

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :pet_id, uniqueness: { scope: :cart_id }

  def line_cents = quantity * pet.price_cents
end
