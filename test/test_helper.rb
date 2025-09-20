ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "minitest/pride"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Performance tracking for tests
    def assert_performance(max_time: 1.0, &block)
      time = Benchmark.realtime(&block)
      assert time < max_time, "Performance assertion failed: #{time}s > #{max_time}s"
    end

    # Risk assessment helpers
    def with_low_risk
      stub_risk_assessment(:low) { yield }
    end

    def with_high_risk
      stub_risk_assessment(:high) { yield }
    end

    def stub_risk_assessment(level)
      original = Rails.configuration.risk_threshold
      Rails.configuration.risk_threshold = case level
                                           when :low then 0.9
                                           when :medium then 0.5
                                           when :high then 0.1
                                           else 0.5
                                           end
      yield
    ensure
      Rails.configuration.risk_threshold = original
    end

    # Redis helpers
    def with_clean_redis
      Redis.current.flushdb
      yield
    ensure
      Redis.current.flushdb
    end

    # Metric collection helpers
    def count_queries(&block)
      count = 0
      counter = ->(name, started, finished, unique_id, payload) { count += 1 unless payload[:sql] =~ /SCHEMA/ }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &block)
      count
    end

    def assert_queries(expected_count, &block)
      actual_count = count_queries(&block)
      assert_equal expected_count, actual_count, "Expected #{expected_count} queries but got #{actual_count}"
    end

    # Stub external services
    def stub_external_services
      # Stub Redis
      Redis.current.set('supplier_api:status', 'up')
      Redis.current.set('shipping:delays', 0)
      Redis.current.set('payment:errors', 0)

      # Stub monitoring metrics
      Redis.current.set('system:cpu_usage', 30)
      Redis.current.set('system:memory_usage', 50)
    end
  end
end

# ActionDispatch Integration Test extensions
class ActionDispatch::IntegrationTest
  # Helper to sign in a user for integration tests
  def sign_in(user)
    post login_path, params: { email: user.email, password: 'password' }
  end

  def sign_out
    delete logout_path
  end

  # Assert response includes performance headers
  def assert_performance_headers
    assert response.headers['X-Response-Time'].present?
    assert response.headers['X-Risk-Level'].present?
  end

  # Assert risk assessment was performed
  def assert_risk_assessed
    assert_not_nil assigns(:current_risk_level)
  end
end