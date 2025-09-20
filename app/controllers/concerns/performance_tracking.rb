module PerformanceTracking
  extend ActiveSupport::Concern

  included do
    around_action :track_action_performance
  end

  def track_action_performance
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    start_memory = GC.stat[:heap_allocated_objects]

    begin
      yield
    ensure
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end_memory = GC.stat[:heap_allocated_objects]

      duration = ((end_time - start_time) * 1000).round(2) # Convert to milliseconds
      memory_delta = end_memory - start_memory

      log_performance_metrics(duration, memory_delta)
      check_performance_thresholds(duration, memory_delta)
    end
  end

  private

  def log_performance_metrics(duration, memory_delta)
    metrics = {
      controller: controller_name,
      action: action_name,
      duration_ms: duration,
      memory_objects: memory_delta,
      status: response.status,
      timestamp: Time.current
    }

    Rails.logger.info "[PERFORMANCE] #{metrics.to_json}"

    # Store in Redis for real-time monitoring
    Redis.current.lpush('response_times', duration)
    Redis.current.ltrim('response_times', 0, 999) # Keep last 1000

    # Track slow requests
    if duration > Rails.configuration.slow_query_threshold
      Redis.current.zadd('slow_requests', duration, "#{controller_name}##{action_name}:#{Time.current.to_i}")
    end
  end

  def check_performance_thresholds(duration, memory_delta)
    if duration > 1000 # 1 second
      Rails.logger.warn "[SLOW REQUEST] #{controller_name}##{action_name} took #{duration}ms"
      StatsD.increment('slow_requests')
    end

    if memory_delta > 100_000 # 100k objects
      Rails.logger.warn "[HIGH MEMORY] #{controller_name}##{action_name} allocated #{memory_delta} objects"
      StatsD.increment('high_memory_requests')
    end
  end

  def with_performance_logging(operation_name)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = yield

    duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)
    Rails.logger.info "[OPERATION] #{operation_name} completed in #{duration}ms"

    result
  end
end