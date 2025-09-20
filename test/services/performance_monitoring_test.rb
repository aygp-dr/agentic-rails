require 'test_helper'
require 'benchmark'

class PerformanceMonitoringTest < ActiveSupport::TestCase
  setup do
    @collector = DevOps::Monitoring::MetricsCollector
    @alert_engine = DevOps::Monitoring::AlertEngine

    # Clear Redis metrics
    Redis.current.flushdb
  end

  # MetricsCollector tests
  test "should collect application metrics" do
    # Seed some metrics
    Redis.current.set('request_count', 1000)
    Redis.current.set('error_count', 10)
    Redis.current.rpush('response_times', [50, 75, 100, 125, 150])

    metrics = @collector.send(:collect_application_metrics)

    assert_equal 1000, metrics[:requests][:total]
    assert_equal 10, metrics[:requests][:errors]
    assert metrics[:performance][:avg_response_time] > 0
  end

  test "should calculate percentile response times" do
    # Add response times
    times = (1..100).to_a
    Redis.current.del('response_times')
    times.each { |t| Redis.current.rpush('response_times', t) }

    p95 = @collector.send(:percentile_response_time, 95)
    p99 = @collector.send(:percentile_response_time, 99)

    assert_equal 95, p95
    assert_equal 99, p99
  end

  test "should calculate APDEX score" do
    Redis.current.set('apdex_satisfied', 80)
    Redis.current.set('apdex_tolerating', 15)
    Redis.current.set('apdex_total', 100)

    apdex = @collector.send(:calculate_apdex)

    # APDEX = (satisfied + tolerating/2) / total
    # (80 + 15/2) / 100 = 87.5 / 100 = 0.875
    assert_equal 0.875, apdex
  end

  test "should track cache performance" do
    Redis.current.set('cache_hits', 900)
    Redis.current.set('cache_requests', 1000)

    hit_rate = @collector.send(:cache_hit_rate)

    assert_equal 0.9, hit_rate
  end

  test "should monitor database pool usage" do
    pool_usage = @collector.send(:db_pool_usage_percentage)

    assert pool_usage >= 0
    assert pool_usage <= 100
  end

  test "should collect infrastructure metrics" do
    metrics = @collector.send(:collect_infrastructure_metrics)

    assert metrics[:cpu].key?(:usage)
    assert metrics[:memory].key?(:used)
    assert metrics[:disk].key?(:usage)
    assert metrics[:network].key?(:connections)
  end

  test "should store metrics in Redis with retention" do
    metrics = {
      timestamp: Time.current,
      application: { requests: { total: 100 } }
    }

    @collector.send(:store_metrics, metrics)

    stored = Redis.current.get("metrics:#{metrics[:timestamp].to_i}")
    assert_not_nil stored

    parsed = JSON.parse(stored)
    assert_equal 100, parsed['application']['requests']['total']
  end

  # AlertEngine tests
  test "should trigger alert for high response time" do
    metrics = {
      application: {
        performance: {
          avg_response_time: 600, # Above 500ms threshold
          apdex: 0.85
        },
        requests: { success_rate: 0.98 }
      }
    }

    alerts = []
    Alert.stub(:create!, ->(params) { alerts << params }) do
      engine = @alert_engine.new(metrics)
      engine.send(:check_performance_alerts)
    end

    assert alerts.any? { |a| a[:alert_type] == :high_response_time }
    assert_equal :warning, alerts.first[:severity]
  end

  test "should trigger critical alert for low APDEX" do
    metrics = {
      application: {
        performance: {
          avg_response_time: 300,
          apdex: 0.65 # Below 0.7 threshold
        },
        requests: { success_rate: 0.98 }
      }
    }

    alerts = []
    Alert.stub(:create!, ->(params) { alerts << params }) do
      engine = @alert_engine.new(metrics)
      engine.send(:check_performance_alerts)
    end

    assert alerts.any? { |a| a[:alert_type] == :low_apdex }
    assert_equal :critical, alerts.find { |a| a[:alert_type] == :low_apdex }[:severity]
  end

  test "should trigger infrastructure alerts for high CPU" do
    metrics = {
      infrastructure: {
        cpu: { usage: 85 }, # Above 80% threshold
        memory: { free: 2000 },
        disk: { usage: 50 }
      }
    }

    alerts = []
    Alert.stub(:create!, ->(params) { alerts << params }) do
      engine = @alert_engine.new(metrics)
      engine.send(:check_infrastructure_alerts)
    end

    assert alerts.any? { |a| a[:alert_type] == :high_cpu_usage }
  end

  test "should trigger security alert for brute force attempts" do
    metrics = {
      risks: {
        security: {
          failed_auth_attempts: 150, # Above 100 threshold
          suspicious_requests: 10,
          blocked_ips: 5
        },
        stability: {
          rollback_rate: 0.05,
          mttr: 30,
          mtbf: 10080
        }
      }
    }

    alerts = []
    Alert.stub(:create!, ->(params) { alerts << params }) do
      engine = @alert_engine.new(metrics)
      engine.send(:check_risk_alerts)
    end

    assert alerts.any? { |a| a[:alert_type] == :brute_force_detected }
    assert_equal :critical, alerts.find { |a| a[:alert_type] == :brute_force_detected }[:severity]
  end

  # Performance benchmarks
  test "metrics collection should be fast" do
    time = Benchmark.realtime do
      @collector.send(:collect_all_metrics)
    end

    assert time < 0.1, "Metrics collection took #{time}s, should be under 100ms"
  end

  test "alert checking should be fast" do
    metrics = @collector.send(:collect_all_metrics)

    time = Benchmark.realtime do
      @alert_engine.new(metrics).check_all_conditions
    end

    assert time < 0.05, "Alert checking took #{time}s, should be under 50ms"
  end

  # Integration tests
  test "should broadcast metrics via ActionCable" do
    broadcasts = []
    ActionCable.server.stub(:broadcast, ->(channel, data) {
      broadcasts << { channel: channel, data: data }
    }) do
      metrics = { timestamp: Time.current, application: {} }
      @collector.send(:broadcast_metrics, metrics)
    end

    assert_equal 1, broadcasts.size
    assert_equal 'metrics_channel', broadcasts.first[:channel]
    assert_equal 'metrics_update', broadcasts.first[:data][:type]
  end

  test "should handle missing Redis keys gracefully" do
    # Clear all Redis data
    Redis.current.flushdb

    assert_nothing_raised do
      metrics = @collector.send(:collect_application_metrics)
      assert_equal 0, metrics[:requests][:total]
      assert_equal 0, metrics[:performance][:avg_response_time]
    end
  end

  # End-to-end monitoring test
  test "full monitoring cycle should work" do
    # Simulate application activity
    100.times do |i|
      Redis.current.incr('request_count')
      Redis.current.rpush('response_times', rand(50..150))
      Redis.current.incr('cache_hits') if i.even?
      Redis.current.incr('cache_requests')
    end

    # Collect metrics
    metrics = @collector.send(:collect_all_metrics)

    # Verify metrics collected
    assert_equal 100, metrics[:application][:requests][:total]
    assert metrics[:application][:performance][:avg_response_time] > 0
    assert metrics[:application][:cache][:hit_rate].between?(0.4, 0.6)

    # Check alerts
    alerts = []
    Alert.stub(:create!, ->(params) { alerts << params }) do
      @alert_engine.new(metrics).check_all_conditions
    end

    # Should have some alerts based on random data
    assert alerts.any? || metrics[:application][:performance][:avg_response_time] < 500
  end
end