# Comprehensive Monitoring Module
# Integrates performance tracking with risk assessment
module DevOps
  module Monitoring
    class MetricsCollector
      include ActiveSupport::Configurable

      config_accessor :collection_interval, default: 60 # seconds
      config_accessor :retention_period, default: 7.days

      class << self
        def start
          Thread.new do
            loop do
              collect_all_metrics
              sleep collection_interval
            end
          end
        end

        def collect_all_metrics
          timestamp = Time.current

          metrics = {
            timestamp: timestamp,
            application: collect_application_metrics,
            infrastructure: collect_infrastructure_metrics,
            business: collect_business_metrics,
            risks: collect_risk_metrics
          }

          store_metrics(metrics)
          broadcast_metrics(metrics)
          check_alerts(metrics)
        end

        private

        def collect_application_metrics
          {
            requests: {
              total: request_count,
              rate: requests_per_second,
              errors: error_count,
              success_rate: success_rate
            },
            performance: {
              avg_response_time: average_response_time,
              p95_response_time: percentile_response_time(95),
              p99_response_time: percentile_response_time(99),
              apdex: calculate_apdex
            },
            cache: {
              hit_rate: cache_hit_rate,
              misses: cache_misses,
              evictions: cache_evictions
            },
            database: {
              active_connections: active_db_connections,
              pool_usage: db_pool_usage_percentage,
              slow_queries: slow_query_count,
              deadlocks: deadlock_count
            },
            background_jobs: {
              queued: jobs_queued,
              processing: jobs_processing,
              failed: jobs_failed,
              retry_queue: jobs_in_retry
            }
          }
        end

        def collect_infrastructure_metrics
          {
            cpu: {
              usage: cpu_usage_percentage,
              load_avg: load_average,
              iowait: io_wait_percentage
            },
            memory: {
              used: memory_used_mb,
              free: memory_free_mb,
              swap: swap_usage_percentage,
              gc_time: garbage_collection_time
            },
            disk: {
              usage: disk_usage_percentage,
              iops: disk_iops,
              throughput: disk_throughput_mbps
            },
            network: {
              bandwidth_in: network_in_mbps,
              bandwidth_out: network_out_mbps,
              connections: active_connections,
              packet_loss: packet_loss_percentage
            }
          }
        end

        def collect_business_metrics
          {
            users: {
              active: active_user_count,
              new: new_users_today,
              churn: churn_rate
            },
            revenue: {
              daily: daily_revenue,
              conversion_rate: conversion_rate,
              cart_abandonment: cart_abandonment_rate
            },
            engagement: {
              session_duration: avg_session_duration,
              page_views: page_views_per_session,
              bounce_rate: bounce_rate
            }
          }
        end

        def collect_risk_metrics
          {
            security: {
              failed_auth_attempts: failed_login_count,
              suspicious_requests: suspicious_request_count,
              blocked_ips: blocked_ip_count
            },
            compliance: {
              data_retention_compliance: check_data_retention,
              audit_log_status: audit_log_health,
              encryption_status: encryption_compliance
            },
            stability: {
              deployment_frequency: deployments_this_week,
              rollback_rate: rollback_percentage,
              mttr: mean_time_to_recovery,
              mtbf: mean_time_between_failures
            }
          }
        end

        def store_metrics(metrics)
          # Store in time-series database
          InfluxDB.write_point('application_metrics', values: metrics)

          # Store in Redis for quick access
          Redis.current.setex(
            "metrics:#{metrics[:timestamp].to_i}",
            retention_period,
            metrics.to_json
          )
        end

        def broadcast_metrics(metrics)
          ActionCable.server.broadcast(
            'metrics_channel',
            {
              type: 'metrics_update',
              data: metrics
            }
          )
        end

        def check_alerts(metrics)
          AlertEngine.new(metrics).check_all_conditions
        end

        # Helper methods for metric collection
        def request_count
          Redis.current.get('request_count').to_i
        end

        def requests_per_second
          Redis.current.get('requests_per_second').to_f
        end

        def average_response_time
          times = Redis.current.lrange('response_times', 0, -1).map(&:to_f)
          times.sum / times.size.to_f
        rescue
          0
        end

        def percentile_response_time(percentile)
          times = Redis.current.lrange('response_times', 0, -1).map(&:to_f).sort
          index = (percentile / 100.0 * times.size).ceil - 1
          times[index] || 0
        end

        def calculate_apdex
          satisfied = Redis.current.get('apdex_satisfied').to_i
          tolerating = Redis.current.get('apdex_tolerating').to_i
          total = Redis.current.get('apdex_total').to_i

          return 1.0 if total.zero?

          (satisfied + tolerating / 2.0) / total
        end

        def cache_hit_rate
          hits = Redis.current.get('cache_hits').to_i
          total = Redis.current.get('cache_requests').to_i

          return 0 if total.zero?
          hits.to_f / total
        end

        def active_db_connections
          ActiveRecord::Base.connection_pool.connections.size
        end

        def db_pool_usage_percentage
          pool = ActiveRecord::Base.connection_pool
          (pool.connections.size.to_f / pool.size) * 100
        end

        def cpu_usage_percentage
          `mpstat 1 1 | awk '$12 ~ /[0-9.]+/ { print 100 - $12 }'`.to_f
        end

        def memory_used_mb
          `free -m | awk 'NR==2{print $3}'`.to_i
        end

        def load_average
          `uptime | awk -F'load average:' '{print $2}'`.strip
        end
      end
    end

    class AlertEngine
      attr_reader :metrics

      def initialize(metrics)
        @metrics = metrics
      end

      def check_all_conditions
        check_performance_alerts
        check_infrastructure_alerts
        check_risk_alerts
        check_business_alerts
      end

      private

      def check_performance_alerts
        if metrics[:application][:performance][:avg_response_time] > 500
          trigger_alert(:high_response_time, severity: :warning)
        end

        if metrics[:application][:performance][:apdex] < 0.7
          trigger_alert(:low_apdex, severity: :critical)
        end

        if metrics[:application][:requests][:success_rate] < 0.95
          trigger_alert(:high_error_rate, severity: :critical)
        end
      end

      def check_infrastructure_alerts
        if metrics[:infrastructure][:cpu][:usage] > 80
          trigger_alert(:high_cpu_usage, severity: :warning)
        end

        if metrics[:infrastructure][:memory][:free] < 500
          trigger_alert(:low_memory, severity: :critical)
        end

        if metrics[:infrastructure][:disk][:usage] > 90
          trigger_alert(:disk_space_critical, severity: :critical)
        end
      end

      def check_risk_alerts
        if metrics[:risks][:security][:failed_auth_attempts] > 100
          trigger_alert(:brute_force_detected, severity: :critical)
        end

        if metrics[:risks][:stability][:rollback_rate] > 0.1
          trigger_alert(:high_rollback_rate, severity: :warning)
        end
      end

      def check_business_alerts
        if metrics[:business][:revenue][:conversion_rate] < 0.01
          trigger_alert(:low_conversion_rate, severity: :warning)
        end

        if metrics[:business][:users][:churn] > 0.1
          trigger_alert(:high_churn_rate, severity: :warning)
        end
      end

      def trigger_alert(alert_type, severity:)
        Alert.create!(
          alert_type: alert_type,
          severity: severity,
          metrics: metrics,
          triggered_at: Time.current
        )

        notify_teams(alert_type, severity)
      end

      def notify_teams(alert_type, severity)
        # Send notifications via multiple channels
        SlackNotifier.notify(alert_type, severity, metrics)
        PagerDuty.trigger(alert_type, severity) if severity == :critical
        EmailNotifier.send_alert(alert_type, metrics)
      end
    end
  end
end