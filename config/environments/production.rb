require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code caching
  config.enable_reloading = false
  config.eager_load = true

  # Full error reports are disabled
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Static file serving
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || ENV["RENDER"].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # Compress responses
  config.middleware.use Rack::Deflater

  # Asset compilation
  config.assets.compile = false
  config.assets.css_compressor = :sass
  config.assets.js_compressor = :uglifier

  # Store files on Amazon S3
  config.active_storage.variant_processor = :mini_magick

  # Force SSL
  config.force_ssl = true

  # Logging
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym
  config.log_tags = [:request_id]
  config.log_formatter = ::Logger::Formatter.new

  # Use lograge for structured logging
  config.lograge.enabled = true
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Cache store
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL"),
    expires_in: 1.hour,
    namespace: "cache",
    pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i
  }

  # Job queue
  config.active_job.queue_adapter = :sidekiq
  config.active_job.queue_name_prefix = "agentic_rails_production"

  # Action Cable
  config.action_cable.mount_path = "/cable"
  config.action_cable.url = ENV.fetch("ACTION_CABLE_URL", "wss://example.com/cable")
  config.action_cable.allowed_request_origins = [
    ENV.fetch("APPLICATION_HOST"),
    /https:\/\/.*\.example\.com/
  ]

  # Mailer settings
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST") }

  # I18n
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # Risk monitoring
  config.risk_monitoring = true
  config.risk_threshold = ENV.fetch("RISK_THRESHOLD", 0.3).to_f

  # Performance tracking
  config.performance_tracking = true
  config.slow_query_threshold = ENV.fetch("SLOW_QUERY_THRESHOLD", 100).to_i

  # Security headers
  config.middleware.use Rack::Attack

  # Health check
  config.middleware.insert_before 0, Rack::HealthCheck
end