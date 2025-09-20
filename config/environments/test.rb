require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Test environment configuration
  config.enable_reloading = false
  config.eager_load = false

  # Configure public file server for tests
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in tests
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on local system in tests
  config.active_storage.service = :test

  # Mailer settings
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test

  # Print deprecation notices
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Raise on missing translations
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view
  config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Risk monitoring for testing
  config.risk_monitoring = true
  config.risk_threshold = 0.7

  # Performance tracking for testing
  config.performance_tracking = true
  config.slow_query_threshold = 10 # ms - more strict in tests
end