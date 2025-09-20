#!/usr/bin/env ruby
# Standalone Risk-Aware Demo (no Rails dependencies)

module RiskAware
  def risk_score
    weights = {
      feature: 0.25,
      dependency: 0.35,
      model: 0.20,
      environmental: 0.20
    }

    score = weights.sum do |type, weight|
      send("#{type}_risk") * weight
    end

    [score, 1.0].min
  end

  def risk_level
    case risk_score
    when 0..0.3 then :low
    when 0.3..0.7 then :medium
    else :high
    end
  end

  def suggested_mitigations
    mitigations = []
    mitigations << "Increase inventory levels" if dependency_risk > 0.5
    mitigations << "Enable feature flags for gradual rollout" if feature_risk > 0.5
    mitigations << "Add monitoring and alerts" if model_risk > 0.5
    mitigations << "Review compliance requirements" if environmental_risk > 0.5
    mitigations << "No immediate action required" if mitigations.empty?
    mitigations
  end
end

class DemoProduct
  include RiskAware

  attr_accessor :name, :inventory

  def initialize(name, inventory = 100)
    @name = name
    @inventory = inventory
  end

  def feature_risk
    0.3  # Low risk for established features
  end

  def dependency_risk
    @inventory < 10 ? 0.8 : 0.2  # High risk if low inventory
  end

  def model_risk
    0.4  # Medium complexity
  end

  def environmental_risk
    0.2  # Low environmental risk
  end
end

# Demo
puts "╔═══════════════════════════════════════════╗"
puts "║         AGENTIC RAILS FRAMEWORK           ║"
puts "║     Risk-Aware Development Demo           ║"
puts "╚═══════════════════════════════════════════╝"
puts

product = DemoProduct.new("AI Assistant", 5)
puts "Product: #{product.name}"
puts "Inventory: #{product.inventory} units"
puts
puts "Risk Breakdown:"
puts "  Feature Risk:       #{'█' * (product.feature_risk * 10).to_i}#{'░' * (10 - product.feature_risk * 10).to_i} (#{product.feature_risk})"
puts "  Dependency Risk:    #{'█' * (product.dependency_risk * 10).to_i}#{'░' * (10 - product.dependency_risk * 10).to_i} (#{product.dependency_risk})"
puts "  Model Risk:         #{'█' * (product.model_risk * 10).to_i}#{'░' * (10 - product.model_risk * 10).to_i} (#{product.model_risk})"
puts "  Environmental Risk: #{'█' * (product.environmental_risk * 10).to_i}#{'░' * (10 - product.environmental_risk * 10).to_i} (#{product.environmental_risk})"
puts
puts "═" * 45
puts "Overall Risk Score: #{product.risk_score.round(2)}"
puts "Risk Level: #{product.risk_level.to_s.upcase}"
puts "═" * 45
puts
puts "Suggested Mitigations:"
product.suggested_mitigations.each_with_index do |m, i|
  puts "  #{i+1}. #{m}"
end
puts

# Show different scenario
puts "Testing with higher inventory..."
product.inventory = 100
puts "Inventory: #{product.inventory} units"
puts "New Risk Score: #{product.risk_score.round(2)}"
puts "New Risk Level: #{product.risk_level.to_s.upcase}"