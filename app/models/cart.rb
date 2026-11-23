# A cart belongs to one browser session (its token). All changes go through
# here so the invariants stay in one place: quantity >= 1, never more than the
# stock, and the total is always the sum of the line items.
class Cart < ApplicationRecord
  class OutOfStock < StandardError; end

  has_many :items, class_name: "CartItem", dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  validates :token, presence: true, uniqueness: true

  def add(pet, quantity = 1)
    transaction do
      item = items.find_or_initialize_by(pet: pet)
      wanted = (item.quantity || 0) + quantity
      raise OutOfStock, "#{pet.name}: only #{pet.stock} in stock" if wanted > pet.stock
      item.update!(quantity: wanted)
      item
    end
  end

  def set_quantity(pet, quantity)
    item = items.find_by(pet: pet)
    return remove(pet) if quantity <= 0
    raise OutOfStock, "#{pet.name}: only #{pet.stock} in stock" if quantity > pet.stock
    item ? item.tap { _1.update!(quantity: quantity) } : add(pet, quantity)
  end

  def remove(pet)
    items.where(pet: pet).destroy_all
    items.reset # the loaded list would still hold the deleted row
    nil
  end

  def total_cents = items.includes(:pet).sum { _1.quantity * _1.pet.price_cents }
  def item_count = items.sum(:quantity)
  def empty? = !items.exists?

  def as_summary
    { items: items.includes(:pet).order(:id).map { { sku: _1.pet.sku, name: _1.pet.name, quantity: _1.quantity,
                                                     price_cents: _1.pet.price_cents, line_cents: _1.line_cents } },
      item_count: item_count, total_cents: total_cents }
  end
end
