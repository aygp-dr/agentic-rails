module RiskAssessment
  extend ActiveSupport::Concern

  included do
    helper_method :current_risk_level if respond_to?(:helper_method)
  end

  def assess_action_risk(action_name)
    risk_factors = {
      data_sensitivity: assess_data_sensitivity(action_name),
      user_trust: assess_user_trust,
      system_load: assess_system_load,
      time_of_day: assess_time_risk
    }

    calculate_overall_risk(risk_factors)
  end

  private

  def assess_data_sensitivity(action)
    sensitive_actions = %w[create update destroy payment checkout]
    return 0.8 if sensitive_actions.include?(action.to_s)

    readonly_actions = %w[index show]
    return 0.2 if readonly_actions.include?(action.to_s)

    0.5
  end

  def assess_user_trust
    return 0.9 unless current_user

    factors = []
    factors << (current_user.created_at < 30.days.ago ? 0.2 : 0.5)
    factors << (current_user.orders_count > 5 ? 0.1 : 0.3)
    factors << (current_user.failed_login_attempts > 3 ? 0.8 : 0.2)

    factors.sum / factors.size
  end

  def assess_system_load
    cpu_usage = Redis.current.get('system:cpu_usage').to_f
    memory_usage = Redis.current.get('system:memory_usage').to_f

    if cpu_usage > 80 || memory_usage > 90
      0.9
    elsif cpu_usage > 60 || memory_usage > 70
      0.6
    else
      0.3
    end
  end

  def assess_time_risk
    hour = Time.current.hour

    # Higher risk during off-hours
    case hour
    when 0..5
      0.7 # Late night - higher risk
    when 6..8, 17..19
      0.3 # Peak hours - normal risk
    when 9..16
      0.2 # Business hours - lower risk
    else
      0.5 # Evening - moderate risk
    end
  end

  def calculate_overall_risk(factors)
    weights = {
      data_sensitivity: 0.4,
      user_trust: 0.3,
      system_load: 0.2,
      time_of_day: 0.1
    }

    risk_score = factors.sum { |factor, value| value * weights[factor] }

    {
      score: risk_score.round(2),
      level: risk_level_from_score(risk_score),
      factors: factors,
      timestamp: Time.current
    }
  end

  def risk_level_from_score(score)
    case score
    when 0..0.3 then :low
    when 0.3..0.6 then :medium
    when 0.6..0.8 then :high
    else :critical
    end
  end

  def current_risk_level
    @current_risk_level ||= assess_action_risk(action_name)
  end

  def require_low_risk
    risk = current_risk_level
    if risk[:level] == :high || risk[:level] == :critical
      Rails.logger.warn "[RISK BLOCKED] Action blocked due to #{risk[:level]} risk: #{risk[:score]}"
      render json: { error: 'Action temporarily unavailable due to security concerns' }, status: 503
    end
  end
end