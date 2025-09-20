require 'test_helper'

class ApiWorkflowTest < ActionDispatch::IntegrationTest
  # === INTEGRATION TESTS ===

  setup do
    @user = User.create!(
      email: 'api@example.com',
      password: 'password'
    )

    @product = Product.create!(
      name: 'Test Product',
      price: 99.99,
      inventory_count: 100
    )

    # Stub external services
    stub_external_services
  end

  # Authentication flow
  test "should authenticate user and maintain session" do
    # Login
    post '/api/v1/login', params: {
      email: @user.email,
      password: 'password'
    }

    assert_response :success
    token = JSON.parse(response.body)['token']
    assert_not_nil token

    # Use token for authenticated request
    get '/api/v1/profile', headers: {
      'Authorization' => "Bearer #{token}"
    }

    assert_response :success
    profile = JSON.parse(response.body)
    assert_equal @user.email, profile['email']
  end

  test "should reject invalid credentials" do
    post '/api/v1/login', params: {
      email: @user.email,
      password: 'wrong'
    }

    assert_response :unauthorized
    assert_nil response.headers['Authorization']
  end

  # Product API workflow
  test "should search and filter products" do
    # Create additional products
    Product.create!(name: 'Expensive Item', price: 500, inventory_count: 5)
    Product.create!(name: 'Cheap Item', price: 10, inventory_count: 200)

    # Search by name
    get '/api/v1/products', params: { q: 'Expensive' }
    assert_response :success

    results = JSON.parse(response.body)['products']
    assert_equal 1, results.length
    assert_equal 'Expensive Item', results.first['name']

    # Filter by price range
    get '/api/v1/products', params: {
      min_price: 50,
      max_price: 150
    }
    assert_response :success

    results = JSON.parse(response.body)['products']
    assert_equal 1, results.length
    assert_equal @product.name, results.first['name']
  end

  test "should track product views and update metrics" do
    initial_views = @product.view_count

    3.times do
      get "/api/v1/products/#{@product.id}"
      assert_response :success
    end

    @product.reload
    assert_equal initial_views + 3, @product.view_count
  end

  # Order creation workflow
  test "complete order workflow from cart to delivery" do
    sign_in(@user)

    # Add to cart
    post '/api/v1/cart/items', params: {
      product_id: @product.id,
      quantity: 2
    }
    assert_response :success

    # View cart
    get '/api/v1/cart'
    assert_response :success
    cart = JSON.parse(response.body)
    assert_equal 199.98, cart['total']

    # Checkout
    post '/api/v1/checkout', params: {
      shipping_address: {
        street: '123 Main St',
        city: 'New York',
        state: 'NY',
        zip: '10001'
      },
      payment_method: 'card'
    }
    assert_response :success

    order = JSON.parse(response.body)['order']
    assert_equal 'pending', order['status']
    order_id = order['id']

    # Process payment
    post "/api/v1/orders/#{order_id}/payment", params: {
      card_token: 'tok_visa'
    }
    assert_response :success

    # Check order status
    get "/api/v1/orders/#{order_id}"
    assert_response :success
    order = JSON.parse(response.body)
    assert_equal 'paid', order['status']
  end

  # Risk assessment integration
  test "should trigger fraud check for high-risk orders" do
    sign_in(@user)

    # Create high-value order
    post '/api/v1/orders', params: {
      items: [
        { product_id: @product.id, quantity: 100 }
      ],
      total_amount: 9999
    }

    assert_response :accepted # 202 - pending fraud check

    order = JSON.parse(response.body)['order']
    assert order['fraud_check_required']
    assert_equal 'pending_review', order['status']

    # Simulate fraud check completion
    Order.find(order['id']).update!(
      fraud_check_status: 'approved',
      fraud_check_results: { score: 0.3, approved: true }
    )

    # Retry order processing
    post "/api/v1/orders/#{order['id']}/process"
    assert_response :success

    order = JSON.parse(response.body)
    assert_equal 'processing', order['status']
  end

  # Performance monitoring integration
  test "should track API performance metrics" do
    # Clear metrics
    Redis.current.flushdb

    # Make multiple requests
    10.times do |i|
      get '/api/v1/products', params: { page: i }
      assert_response :success
    end

    # Check metrics were recorded
    request_count = Redis.current.get('request_count').to_i
    assert request_count >= 10

    response_times = Redis.current.lrange('response_times', 0, -1).map(&:to_f)
    assert response_times.any?
    assert response_times.all? { |t| t > 0 && t < 1000 }
  end

  # Error handling
  test "should handle errors gracefully with proper status codes" do
    # 404 - Not found
    get '/api/v1/products/999999'
    assert_response :not_found
    error = JSON.parse(response.body)
    assert_equal 'Product not found', error['error']

    # 422 - Validation error
    post '/api/v1/products', params: {
      product: { name: '', price: -10 }
    }
    assert_response :unprocessable_entity
    errors = JSON.parse(response.body)['errors']
    assert errors['name'].include?("can't be blank")
    assert errors['price'].include?("must be greater than 0")

    # 503 - Service unavailable (high risk)
    # Simulate high system load
    Redis.current.set('system:cpu_usage', 95)
    Redis.current.set('system:memory_usage', 95)

    post '/api/v1/orders', params: {
      items: [{ product_id: @product.id, quantity: 1 }]
    }
    assert_response :service_unavailable
  end

  # Rate limiting
  test "should enforce rate limiting" do
    # Configure aggressive rate limit for testing
    Rack::Attack.throttle('api/ip', limit: 5, period: 1.minute) do |req|
      req.ip
    end

    # Make requests up to limit
    5.times do
      get '/api/v1/products'
      assert_response :success
    end

    # Next request should be rate limited
    get '/api/v1/products'
    assert_response :too_many_requests
    assert response.headers['Retry-After'].present?
  end

  # WebSocket integration
  test "should receive real-time updates via ActionCable" do
    # Connect to WebSocket
    connect "/cable", headers: {
      'Authorization' => "Bearer #{generate_token(@user)}"
    }

    # Subscribe to product updates
    subscribe channel: 'ProductChannel', product_id: @product.id

    # Trigger inventory update
    @product.update!(inventory_count: 5)

    # Assert broadcast was sent
    assert_broadcast_on("product:#{@product.id}", {
      event: 'inventory_update',
      product_id: @product.id,
      inventory_count: 5,
      low_stock: true
    })
  end

  # Multi-step workflow
  test "should handle complex multi-step business workflow" do
    # Step 1: User registration
    post '/api/v1/users', params: {
      user: {
        email: 'newuser@example.com',
        password: 'password',
        first_name: 'New',
        last_name: 'User'
      }
    }
    assert_response :created
    new_user = JSON.parse(response.body)['user']

    # Step 2: Email verification (simulate)
    User.find(new_user['id']).verify_email!

    # Step 3: Login
    post '/api/v1/login', params: {
      email: 'newuser@example.com',
      password: 'password'
    }
    assert_response :success
    token = JSON.parse(response.body)['token']

    # Step 4: Complete profile
    patch '/api/v1/profile', headers: {
      'Authorization' => "Bearer #{token}"
    }, params: {
      user: {
        phone: '555-1234',
        preferences: { newsletter: true }
      }
    }
    assert_response :success

    # Step 5: Make first purchase
    post '/api/v1/orders', headers: {
      'Authorization' => "Bearer #{token}"
    }, params: {
      items: [{ product_id: @product.id, quantity: 1 }]
    }
    assert_response :success

    # Verify user metrics updated
    user = User.find(new_user['id'])
    assert_equal 1, user.orders_count
    assert user.risk_score < 0.5 # New user with successful order
  end

  private

  def generate_token(user)
    # Simplified token generation for testing
    JWT.encode({ user_id: user.id }, Rails.application.secret_key_base)
  end
end