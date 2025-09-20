require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # === UNIT TESTS ===

  setup do
    @user = User.new(
      email: 'test@example.com',
      password: 'SecurePassword123!',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  # Basic validations
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @user.save!
    duplicate = User.new(email: @user.email, password: 'password')
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    invalid_emails = %w[invalid invalid@  @example.com user@]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email} should be invalid"
    end
  end

  test "should downcase email before saving" do
    @user.email = "TEST@EXAMPLE.COM"
    @user.save!
    assert_equal "test@example.com", @user.reload.email
  end

  # Password tests
  test "should require password" do
    @user.password = nil
    assert_not @user.valid?
  end

  test "should enforce minimum password length" do
    @user.password = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should hash password" do
    @user.save!
    assert_not_equal 'SecurePassword123!', @user.password_digest
    assert @user.authenticate('SecurePassword123!')
  end

  # Risk assessment tests
  test "should calculate user risk score based on behavior" do
    @user.save!

    # New user - higher risk
    assert @user.risk_score > 0.3

    # Add failed login attempts
    @user.failed_login_attempts = 5
    @user.save!
    assert @user.risk_score > 0.5

    # Account locked
    @user.locked_at = Time.current
    @user.save!
    assert @user.risk_score > 0.7
  end

  test "should track login metrics" do
    @user.save!
    initial_count = @user.login_count

    @user.record_login!
    assert_equal initial_count + 1, @user.login_count
    assert_not_nil @user.last_login_at
  end

  test "should calculate churn probability" do
    @user.save!

    # Active user - low churn
    @user.last_activity_at = 1.day.ago
    @user.orders_count = 10
    assert @user.churn_probability < 0.3

    # Inactive user - high churn
    @user.last_activity_at = 60.days.ago
    @user.orders_count = 1
    assert @user.churn_probability > 0.6
  end

  # Scope tests
  test "should find active users" do
    active_user = User.create!(
      email: 'active@example.com',
      password: 'password',
      status: 'active'
    )

    inactive_user = User.create!(
      email: 'inactive@example.com',
      password: 'password',
      status: 'inactive'
    )

    assert_includes User.active, active_user
    assert_not_includes User.active, inactive_user
  end

  test "should find high risk users" do
    @user.risk_score = 0.8
    @user.save!

    low_risk = User.create!(
      email: 'low@example.com',
      password: 'password',
      risk_score: 0.2
    )

    assert_includes User.high_risk, @user
    assert_not_includes User.high_risk, low_risk
  end

  # Performance tests
  test "should efficiently load user with associations" do
    @user.save!

    queries = assert_queries(1) do
      User.includes(:orders).find(@user.id)
    end
  end

  # Edge cases
  test "should handle nil values gracefully" do
    user = User.new(email: 'edge@example.com', password: 'password')
    user.first_name = nil
    user.last_name = nil

    assert user.valid?
    assert_equal '', user.full_name
  end

  test "should prevent mass assignment of protected attributes" do
    user = User.new(
      email: 'test@example.com',
      password: 'password',
      risk_score: 0.1  # Should not be assignable
    )

    assert_not_equal 0.1, user.risk_score
  end
end