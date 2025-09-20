class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def check
    health_status = perform_health_checks

    if health_status[:healthy]
      render json: health_status, status: :ok
    else
      render json: health_status, status: :service_unavailable
    end
  end

  private

  def perform_health_checks
    checks = {
      database: check_database,
      redis: check_redis,
      disk_space: check_disk_space,
      memory: check_memory
    }

    failed_checks = checks.select { |_, status| !status[:healthy] }

    {
      status: failed_checks.empty? ? 'healthy' : 'unhealthy',
      healthy: failed_checks.empty?,
      timestamp: Time.current,
      checks: checks,
      version: Rails.application.config.version || 'v0.1.0'
    }
  end

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { healthy: true, response_time: measure_time { Product.first } }
  rescue => e
    { healthy: false, error: e.message }
  end

  def check_redis
    Redis.current.ping
    { healthy: true, response_time: measure_time { Redis.current.get('test') } }
  rescue => e
    { healthy: false, error: e.message }
  end

  def check_disk_space
    usage = `df -h / | tail -1 | awk '{print $5}' | sed 's/%//'`.to_i
    healthy = usage < 90

    { healthy: healthy, usage_percent: usage }
  end

  def check_memory
    if RUBY_PLATFORM =~ /linux/
      free_memory = `free -m | grep Mem | awk '{print $4}'`.to_i
      total_memory = `free -m | grep Mem | awk '{print $2}'`.to_i
      usage_percent = ((total_memory - free_memory).to_f / total_memory * 100).round
    else
      # Fallback for non-Linux systems
      usage_percent = 50
    end

    healthy = usage_percent < 90

    { healthy: healthy, usage_percent: usage_percent }
  end

  def measure_time
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)
  end
end