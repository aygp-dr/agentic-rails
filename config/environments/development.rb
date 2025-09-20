require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In development, code is not cached
  config.enable_reloading = true
  config.eager_load = false

  # Show full error reports
  config.consider_all_requests_local = true
  config.server_timing = true

  # Enable caching with Redis
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Store uploaded files locally
  config.active_storage.variant_processor = :mini_magick

  # Print deprecation notices
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Raise exceptions for unpermitted parameters
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Raise error on missing translations
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names
  config.action_view.annotate_rendered_view_with_filenames = true

  # Prevent N+1 queries
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end

  # Action Cable
  config.action_cable.disable_request_forgery_protection = true

  # Risk monitoring enabled
  config.risk_monitoring = true
  config.risk_threshold = 0.5

  # Performance tracking enabled
  config.performance_tracking = true
  config.slow_query_threshold = 50 # ms
end