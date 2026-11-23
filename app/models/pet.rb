class Pet < ApplicationRecord
  has_many :cart_items, dependent: :restrict_with_error

  validates :sku, :name, :species, presence: true
  validates :sku, uniqueness: true
  validates :price_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :catalogue, -> { order(:species, :name) }

  def price = format("$%.2f", price_cents / 100.0)
  def in_stock? = stock.positive?
end
