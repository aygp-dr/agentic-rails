# Risk-Aware Model Concern
# Implements Risk-First principles from the book
module RiskAware
  extend ActiveSupport::Concern

  included do
    scope :high_risk, -> { where('risk_score > ?', 0.7) }
    scope :needs_review, -> { where(risk_status: 'pending_review') }

    before_save :calculate_risk_score
    after_commit :broadcast_risk_changes, if: :risk_score_previously_changed?
  end

  class_methods do
    def risk_categories
      {
        feature: 'Feature Fit/Implementation Risk',
        dependency: 'Reliability/Schedule Risk',
        model: 'Communication/Complexity Risk',
        environmental: 'Security/Legal/Operational Risk'
      }
    end

    def risk_threshold
      ENV.fetch('RISK_THRESHOLD', 0.5).to_f
    end
  end

  def risk_level
    case risk_score
    when 0..0.3 then :low
    when 0.3..0.7 then :medium
    else :high
    end
  end

  def mitigations_required?
    risk_score > self.class.risk_threshold
  end

  def risk_report
    {
      score: risk_score,
      level: risk_level,
      categories: active_risk_categories,
      mitigations: suggested_mitigations,
      last_assessed: risk_assessed_at
    }
  end

  private

  def calculate_risk_score
    self.risk_score = weighted_risk_calculation
    self.risk_assessed_at = Time.current
  end

  def weighted_risk_calculation
    weights = {
      feature: 0.25,
      dependency: 0.35,
      model: 0.20,
      environmental: 0.20
    }

    weights.sum { |category, weight| send("#{category}_risk") * weight }
  end

  def broadcast_risk_changes
    ActionCable.server.broadcast(
      "risk_monitoring",
      {
        model: self.class.name,
        id: id,
        risk_level: risk_level,
        timestamp: Time.current
      }
    )
  end

  def suggested_mitigations
    mitigations = []
    mitigations << 'Add feature flags' if feature_risk > 0.6
    mitigations << 'Implement circuit breaker' if dependency_risk > 0.7
    mitigations << 'Increase test coverage' if model_risk > 0.5
    mitigations << 'Security audit required' if environmental_risk > 0.8
    mitigations
  end
end