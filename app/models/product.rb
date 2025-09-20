class Product < ApplicationRecord
  include RiskAware
  include PerformanceMonitored

  # Associations
  has_many :order_items
  has_many :orders, through: :order_items
  has_many :reviews

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :available, -> { where('inventory_count > ?', 0) }
  scope :featured, -> { where(featured: true) }
  scope :recently_added, -> { order(created_at: :desc).limit(10) }

  # Risk assessment methods (required by RiskAware)
  def feature_risk
    risk = 0.0
    risk += 0.3 if new_record? # New products are riskier
    risk += 0.2 if inventory_count < 10 # Low inventory risk
    risk += 0.2 if price > average_price * 2 # High price risk
    risk += 0.3 if reviews.where('rating < ?', 3).count > reviews.count * 0.3 # Bad reviews
    [risk, 1.0].min
  end

  def dependency_risk
    risk = 0.0
    risk += 0.4 if supplier_api_down? # External supplier dependency
    risk += 0.3 if shipping_delays? # Logistics dependency
    risk += 0.3 if payment_processor_issues? # Payment dependency
    [risk, 1.0].min
  end

  def model_risk
    risk = 0.0
    risk += 0.2 if description.blank? # Missing data risk
    risk += 0.3 if images.empty? # No product images
    risk += 0.2 if categories.empty? # Uncategorized product
    risk += 0.3 if variants.count > 10 # Complex product structure
    [risk, 1.0].min
  end

  def environmental_risk
    risk = 0.0
    risk += 0.5 if restricted_product? # Legal/compliance risk
    risk += 0.3 if hazardous_material? # Safety risk
    risk += 0.2 if seasonal_product? && out_of_season? # Seasonal risk
    [risk, 1.0].min
  end

  # Performance-critical methods wrapped with monitoring
  def calculate_discount
    with_performance_tracking do
      base_discount = 0.0
      base_discount += 0.1 if inventory_count > 100 # Bulk discount
      base_discount += 0.05 if created_at < 30.days.ago # Old inventory
      base_discount += 0.15 if seasonal_product? && end_of_season?
      base_discount
    end
  end

  def update_inventory(quantity_change)
    with_performance_tracking do
      transaction do
        lock! # Pessimistic locking for inventory
        self.inventory_count += quantity_change

        if inventory_count < 0
          errors.add(:inventory_count, "cannot be negative")
          raise ActiveRecord::Rollback
        end

        save!
        broadcast_inventory_update if inventory_count < 10
      end
    end
  end

  private

  def average_price
    @average_price ||= Product.average(:price) || 50.0
  end

  def supplier_api_down?
    # Check supplier API health
    Redis.current.get('supplier_api:status') == 'down'
  end

  def shipping_delays?
    # Check shipping service status
    Redis.current.get('shipping:delays').to_i > 2
  end

  def payment_processor_issues?
    # Check payment processor health
    Redis.current.get('payment:errors').to_i > 10
  end

  def restricted_product?
    # Check for restricted categories
    categories.any? { |c| c.restricted? }
  end

  def hazardous_material?
    tags.include?('hazmat') || tags.include?('dangerous')
  end

  def seasonal_product?
    categories.any? { |c| c.seasonal? }
  end

  def out_of_season?
    # Simplified season check
    seasonal_category = categories.find(&:seasonal?)
    return false unless seasonal_category

    current_month = Date.current.month
    !seasonal_category.active_months.include?(current_month)
  end

  def end_of_season?
    seasonal_category = categories.find(&:seasonal?)
    return false unless seasonal_category

    current_month = Date.current.month
    seasonal_category.active_months.last == current_month
  end

  def broadcast_inventory_update
    ActionCable.server.broadcast(
      'inventory_channel',
      {
        product_id: id,
        inventory_count: inventory_count,
        low_stock: inventory_count < 10
      }
    )
  end
end