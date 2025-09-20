source 'https://rubygems.org'

ruby '3.3.8'

# Rails and core dependencies
gem 'rails', '~> 7.2.0'
gem 'sprockets-rails'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'redis', '~> 5.0'
gem 'bootsnap', '>= 1.4.4', require: false

# Hotwire and real-time features
gem 'hotwire-rails'

# Background jobs
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-cron'

# Performance and monitoring
gem 'skylight' # Application performance monitoring
gem 'bullet' # N+1 query detection
gem 'rack-mini-profiler'
gem 'memory_profiler'
gem 'flamegraph'
gem 'stackprof'

# Caching
gem 'redis-rails'
gem 'dalli' # Memcached
gem 'rack-cache'

# Database optimization
gem 'database_cleaner-active_record'
gem 'activerecord-import' # Bulk inserts
gem 'ar_lazy_preload' # Automatic preloading
gem 'strong_migrations' # Safe migrations

# Security
gem 'bcrypt', '~> 3.1.7'
gem 'rack-attack' # Rate limiting
gem 'secure_headers'
gem 'brakeman', require: false

# DevOps and deployment
gem 'capistrano', '~> 3.17', require: false
gem 'capistrano-rails', '~> 1.6', require: false
gem 'capistrano-passenger', '~> 0.2.0', require: false
gem 'capistrano-rbenv', '~> 2.2', require: false

# Monitoring and metrics
gem 'prometheus-client'
gem 'influxdb'
gem 'lograge' # Structured logging

# Risk management
gem 'scientist' # Experimentation framework
gem 'flipper' # Feature flags
gem 'flipper-active_record'
gem 'flipper-ui'

# API and serialization
gem 'jsonapi-serializer'
gem 'oj' # Fast JSON parsing

# Testing and quality
group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.8'
  gem 'spring'

  # Code quality
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
  gem 'rails_best_practices', require: false
  gem 'bundler-audit', require: false

  # Development tools
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-brakeman'

  # Performance
  gem 'derailed_benchmarks'
  gem 'benchmark-ips'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'
  gem 'vcr'
  gem 'shoulda-matchers'
  gem 'parallel_tests'
end

# Production optimizations
group :production do
  gem 'rack-timeout'
  gem 'health_check'
end

# Windows specific
gem 'tzinfo-data', platforms: %i[windows jruby]