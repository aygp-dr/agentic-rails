require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module AgenticRails
  class Application < Rails::Application
    config.load_defaults 7.2

    # Risk-aware configuration
    config.risk_threshold = ENV.fetch('RISK_THRESHOLD', 0.5).to_f
    config.enable_risk_monitoring = true

    # Performance monitoring
    config.performance_tracking = true
    config.slow_query_threshold = 50 # ms

    # Caching configuration
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
      expires_in: 1.hour
    }

    # Background jobs
    config.active_job.queue_adapter = :sidekiq

    # Security headers
    config.force_ssl = Rails.env.production?

    # Structured logging
    config.log_tags = [:request_id]
    config.log_level = :info

    # AutoLoad paths
    config.autoload_paths += %W[#{config.root}/lib]

    # Middleware
    config.middleware.use Rack::Attack if Rails.env.production?
  end
end