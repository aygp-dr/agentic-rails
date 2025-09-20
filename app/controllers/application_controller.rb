class ApplicationController < ActionController::Base
  include RiskAssessment
  include PerformanceTracking

  protect_from_forgery with: :exception

  before_action :track_request_metrics
  after_action :assess_request_risk

  rescue_from StandardError, with: :handle_error

  private

  def track_request_metrics
    @request_start_time = Time.current
    Rails.cache.increment('request_count')
  end

  def assess_request_risk
    risk_factors = {
      response_time: Time.current - @request_start_time,
      status_code: response.status,
      user_authenticated: user_signed_in?,
      ip_risk: assess_ip_risk(request.remote_ip)
    }

    if risk_factors[:response_time] > 1.0 || risk_factors[:status_code] >= 400
      log_high_risk_request(risk_factors)
    end
  end

  def assess_ip_risk(ip)
    # Check if IP is in blocklist or has suspicious activity
    blocked_ips = Rails.cache.fetch('blocked_ips') { [] }
    return 'high' if blocked_ips.include?(ip)

    recent_requests = Rails.cache.read("ip:#{ip}:requests") || 0
    return 'medium' if recent_requests > 100

    'low'
  end

  def log_high_risk_request(factors)
    Rails.logger.warn "[HIGH RISK REQUEST] #{factors.to_json}"
    Redis.current.incr('high_risk_requests')
  end

  def handle_error(exception)
    Rails.cache.increment('error_count')

    error_id = SecureRandom.uuid
    Rails.logger.error "[ERROR #{error_id}] #{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    if Rails.env.production?
      render json: { error: 'Internal server error', error_id: error_id }, status: 500
    else
      render json: {
        error: exception.message,
        error_id: error_id,
        backtrace: exception.backtrace
      }, status: 500
    end
  end

  def user_signed_in?
    session[:user_id].present?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if user_signed_in?
  end
  helper_method :current_user

  def require_authentication
    unless user_signed_in?
      redirect_to login_path, alert: 'Please log in to continue'
    end
  end
end