# Performance Monitoring Concern
# Implements concepts from Rails Scales book
module PerformanceMonitored
  extend ActiveSupport::Concern

  included do
    class_attribute :performance_thresholds
    self.performance_thresholds = {
      query_time: 50, # ms
      memory_delta: 10_000_000, # bytes
      cache_miss_rate: 0.2
    }

    around_save :monitor_write_performance
    around_destroy :monitor_delete_performance
  end

  class_methods do
    def monitor_queries
      ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        if event.duration > performance_thresholds[:query_time]
          Rails.logger.warn "[SLOW QUERY] #{name}: #{event.duration}ms - #{event.payload[:sql]}"
          track_performance_issue(:slow_query, event)
        end
      end
    end

    def with_performance_tracking
      start_memory = GC.stat[:heap_allocated_objects]
      result = nil

      time = Benchmark.realtime { result = yield }

      end_memory = GC.stat[:heap_allocated_objects]
      memory_delta = end_memory - start_memory

      if memory_delta > performance_thresholds[:memory_delta]
        Rails.logger.warn "[HIGH MEMORY] #{name}: #{memory_delta} objects allocated"
        track_performance_issue(:high_memory, { objects: memory_delta })
      end

      result
    end

    def cache_performance
      hits = Rails.cache.stats[:hits] || 0
      misses = Rails.cache.stats[:misses] || 0
      total = hits + misses

      return 0 if total.zero?

      miss_rate = misses.to_f / total
      if miss_rate > performance_thresholds[:cache_miss_rate]
        Rails.logger.warn "[CACHE PERFORMANCE] #{name}: #{(miss_rate * 100).round(2)}% miss rate"
      end

      { hit_rate: 1 - miss_rate, total_requests: total }
    end

    private

    def track_performance_issue(issue_type, data)
      PerformanceIssue.create!(
        model_name: name,
        issue_type: issue_type,
        data: data,
        threshold: performance_thresholds[issue_type],
        occurred_at: Time.current
      )
    rescue => e
      Rails.logger.error "Failed to track performance issue: #{e.message}"
    end
  end

  private

  def monitor_write_performance
    time = Benchmark.realtime { yield }

    if time > 100 # ms
      Rails.logger.warn "[SLOW WRITE] #{self.class.name}##{id}: #{time}ms"
    end

    Rails.cache.increment("#{self.class.name}:writes:count")
    Rails.cache.increment("#{self.class.name}:writes:time", time)
  end

  def monitor_delete_performance
    time = Benchmark.realtime { yield }

    if time > 100 # ms
      Rails.logger.warn "[SLOW DELETE] #{self.class.name}##{id}: #{time}ms"
    end
  end
end