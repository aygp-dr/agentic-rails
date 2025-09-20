require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # === UNIT TESTS ===

  setup do
    @user = User.create!(
      email: 'buyer@example.com',
      password: 'password'
    )

    @order = Order.new(
      user: @user,
      order_number: "ORD-#{SecureRandom.hex(8)}",
      total_amount: 99.99,
      status: 'pending'
    )
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @order.valid?
  end

  test "should require user" do
    @order.user = nil
    assert_not @order.valid?
    assert_includes @order.errors[:user], "must exist"
  end

  test "should require unique order number" do
    @order.save!
    duplicate = Order.new(
      user: @user,
      order_number: @order.order_number,
      total_amount: 50
    )
    assert_not duplicate.valid?
  end

  test "should require positive total amount" do
    @order.total_amount = -10
    assert_not @order.valid?

    @order.total_amount = 0
    assert_not @order.valid?

    @order.total_amount = 0.01
    assert @order.valid?
  end

  # State transitions
  test "should transition through order states" do
    @order.save!
    assert_equal 'pending', @order.status

    @order.process_payment!
    assert_equal 'paid', @order.status
    assert_not_nil @order.paid_at

    @order.ship!
    assert_equal 'shipped', @order.status
    assert_not_nil @order.shipped_at

    @order.deliver!
    assert_equal 'delivered', @order.status
    assert_not_nil @order.delivered_at
  end

  test "should allow order cancellation" do
    @order.save!

    @order.cancel!
    assert_equal 'cancelled', @order.status
    assert_not_nil @order.cancelled_at
  end

  test "should prevent invalid state transitions" do
    @order.status = 'delivered'
    @order.save!

    assert_raises(StandardError) { @order.process_payment! }
  end

  # Risk assessment
  test "should calculate fraud risk" do
    @order.save!

    # Normal order - low risk
    assert @order.risk_score < 0.3

    # High value order - increased risk
    @order.total_amount = 10000
    @order.save!
    assert @order.risk_score > 0.5

    # First-time buyer with high value - high risk
    @user.orders_count = 0
    @order.total_amount = 5000
    @order.save!
    assert @order.risk_score > 0.7
    assert @order.fraud_check_required?
  end

  test "should track fulfillment attempts" do
    @order.save!

    3.times { @order.attempt_fulfillment! }

    assert_equal 3, @order.fulfillment_attempts
    assert @order.risk_score > 0.5, "Multiple attempts should increase risk"
  end

  # Performance tracking
  test "should measure processing time" do
    @order.save!

    start_time = Time.current
    @order.with_performance_tracking do
      sleep 0.01  # Simulate processing
      @order.process_payment!
    end

    assert_not_nil @order.processing_time
    assert @order.processing_time > 0
  end

  # Scopes
  test "should find recent orders" do
    old_order = Order.create!(
      user: @user,
      order_number: 'OLD-001',
      total_amount: 50,
      created_at: 2.months.ago
    )

    recent_order = Order.create!(
      user: @user,
      order_number: 'NEW-001',
      total_amount: 50,
      created_at: 1.day.ago
    )

    assert_includes Order.recent, recent_order
    assert_not_includes Order.recent, old_order
  end

  test "should find orders by status" do
    @order.save!

    paid_order = Order.create!(
      user: @user,
      order_number: 'PAID-001',
      total_amount: 50,
      status: 'paid'
    )

    assert_includes Order.pending, @order
    assert_not_includes Order.pending, paid_order

    assert_includes Order.paid, paid_order
    assert_not_includes Order.paid, @order
  end

  # Calculations
  test "should calculate order totals correctly" do
    @order.tax_amount = 10
    @order.shipping_amount = 5

    assert_equal 114.99, @order.grand_total
  end

  test "should calculate estimated delivery date" do
    @order.save!
    @order.ship!

    estimated = @order.estimated_delivery_date
    assert estimated > Time.current
    assert estimated < 7.days.from_now
  end

  # Edge cases
  test "should handle missing addresses gracefully" do
    @order.shipping_address = nil
    @order.billing_address = nil

    assert @order.valid?
    assert_nil @order.formatted_shipping_address
  end

  test "should prevent negative tax and shipping" do
    @order.tax_amount = -5
    assert_not @order.valid?

    @order.tax_amount = 0
    @order.shipping_amount = -10
    assert_not @order.valid?
  end
end