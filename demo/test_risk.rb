#!/usr/bin/env ruby
# Demonstrate Risk-Aware module

require_relative '../app/models/concerns/risk_aware'

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
puts "═══ RISK-AWARE DEMO ═══"
puts

product = DemoProduct.new("AI Assistant", 5)
puts "Product: #{product.name}"
puts "Inventory: #{product.inventory} units"
puts
puts "Risk Assessment:"
puts "  Feature Risk:      #{product.feature_risk}"
puts "  Dependency Risk:   #{product.dependency_risk}"
puts "  Model Risk:        #{product.model_risk}"
puts "  Environmental Risk: #{product.environmental_risk}"
puts
puts "Overall Risk Score: #{product.risk_score.round(2)}"
puts "Risk Level: #{product.risk_level.to_s.upcase}"
puts
puts "Suggested Mitigations:"
product.suggested_mitigations.each_with_index do |m, i|
  puts "  #{i+1}. #{m}"
end