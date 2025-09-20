require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  setup do
    @product = Product.new(
      name: "Test Product",
      price: 99.99,
      inventory_count: 50,
      description: "A test product"
    )
  end

  # Basic validations
  test "should be valid with valid attributes" do
    assert @product.valid?
  end

  test "should require name" do
    @product.name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:name], "can't be blank"
  end

  test "should require price" do
    @product.price = nil
    assert_not @product.valid?
    assert_includes @product.errors[:price], "can't be blank"
  end

  test "should not allow negative price" do
    @product.price = -10
    assert_not @product.valid?
    assert_includes @product.errors[:price], "must be greater than or equal to 0"
  end

  # Risk assessment tests
  test "should calculate feature risk for new products" do
    assert @product.new_record?
    assert @product.feature_risk >= 0.3
  end

  test "should increase feature risk for low inventory" do
    @product.inventory_count = 5
    assert @product.feature_risk >= 0.5
  end

  test "should calculate dependency risk when supplier is down" do
    Redis.current.set('supplier_api:status', 'down')
    assert_equal 0.4, @product.dependency_risk
    Redis.current.del('supplier_api:status')
  end

  test "should calculate model risk for missing description" do
    @product.description = ''
    assert @product.model_risk >= 0.2
  end

  test "should calculate environmental risk for restricted products" do
    # Mock restricted product
    @product.stub(:restricted_product?, true) do
      assert_equal 0.5, @product.environmental_risk
    end
  end

  # Risk-aware concern integration
  test "should calculate overall risk score" do
    @product.save!
    assert_not_nil @product.risk_score
    assert @product.risk_score.between?(0, 1)
  end

  test "should determine risk level" do
    @product.risk_score = 0.2
    assert_equal :low, @product.risk_level

    @product.risk_score = 0.5
    assert_equal :medium, @product.risk_level

    @product.risk_score = 0.8
    assert_equal :high, @product.risk_level
  end

  test "should suggest mitigations for high risks" do
    @product.stub(:feature_risk, 0.7) do
      @product.stub(:dependency_risk, 0.8) do
        mitigations = @product.suggested_mitigations
        assert_includes mitigations, 'Add feature flags'
        assert_includes mitigations, 'Implement circuit breaker'
      end
    end
  end

  # Performance monitoring tests
  test "should track performance of discount calculation" do
    # Mock performance tracking
    start_time = Time.current

    @product.stub(:with_performance_tracking, ->(&block) {
      result = block.call
      elapsed = Time.current - start_time
      assert elapsed < 0.1 # Should be fast
      result
    }) do
      discount = @product.calculate_discount
      assert discount.between?(0, 1)
    end
  end

  test "should monitor inventory update performance" do
    @product.save!

    assert_difference '@product.inventory_count', -5 do
      @product.update_inventory(-5)
    end
  end

  test "should not allow negative inventory" do
    @product.save!

    assert_no_difference '@product.inventory_count' do
      @product.update_inventory(-100)
    end
    assert_includes @product.errors[:inventory_count], "cannot be negative"
  end

  # Scope tests
  test "available scope should return products with inventory" do
    @product.save!
    out_of_stock = Product.create!(name: "Out of Stock", price: 10, inventory_count: 0)

    available = Product.available
    assert_includes available, @product
    assert_not_includes available, out_of_stock
  end

  test "featured scope should return featured products" do
    @product.featured = true
    @product.save!

    regular = Product.create!(name: "Regular", price: 10, featured: false)

    featured = Product.featured
    assert_includes featured, @product
    assert_not_includes featured, regular
  end

  # Integration with ActionCable
  test "should broadcast inventory updates when low" do
    @product.save!

    # Mock ActionCable broadcast
    ActionCable.server.stub(:broadcast, ->(channel, data) {
      assert_equal 'inventory_channel', channel
      assert_equal @product.id, data[:product_id]
      assert data[:low_stock]
    }) do
      @product.update_inventory(-45) # Brings inventory to 5
    end
  end
end