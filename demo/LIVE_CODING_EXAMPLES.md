# Agentic Rails - Live Coding Examples

## 🎯 Live Coding Session Guide

**Duration**: 30-45 minutes
**Format**: Terminal-based demonstration
**Audience**: Developers wanting hands-on experience

---

## Setup (2 minutes)

### Terminal Layout
```bash
# Start tmux session
tmux new-session -s live-demo

# Split into 4 panes:
# - Top-left: Editor (vim/nano)
# - Top-right: Rails server
# - Bottom-left: Rails console
# - Bottom-right: Monitoring

tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v
```

---

## Example 1: Risk-Aware Product Model (8 minutes)

### Step 1: Create the Model
```ruby
# In editor pane
cat > app/models/demo_product.rb << 'EOF'
class DemoProduct < ApplicationRecord
  include RiskAware
  include PerformanceMonitored
  
  # Define risk factors
  def feature_risk
    return 0.9 if new_feature_enabled?
    return 0.7 if recently_changed?
    0.2
  end
  
  def dependency_risk
    return 0.8 if supplier_api_down?
    return 0.5 if shipping_delays?
    0.1
  end
  
  def model_risk
    return 0.6 if inventory_count < 10
    return 0.4 if price_changed_recently?
    0.2
  end
  
  def environmental_risk
    return 0.7 if peak_season?
    return 0.5 if compliance_pending?
    0.1
  end
  
  private
  
  def new_feature_enabled?
    created_at > 7.days.ago
  end
  
  def recently_changed?
    updated_at > 1.day.ago
  end
  
  def supplier_api_down?
    Redis.current.get('supplier_api:status') == 'down'
  end
  
  def shipping_delays?
    Redis.current.get('shipping:delays').to_i > 3
  end
  
  def peak_season?
    [11, 12].include?(Date.current.month)
  end
  
  def price_changed_recently?
    # Check audit log for price changes
    false
  end
  
  def compliance_pending?
    false
  end
end
EOF
```

### Step 2: Create Migration
```bash
rails generate migration CreateDemoProducts
```

```ruby
# Edit the migration
cat > db/migrate/*_create_demo_products.rb << 'EOF'
class CreateDemoProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :demo_products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2
      t.integer :inventory_count, default: 0
      t.jsonb :risk_history, default: {}
      t.jsonb :performance_metrics, default: {}
      
      t.timestamps
    end
    
    add_index :demo_products, :name
    add_index :demo_products, :created_at
    add_index :demo_products, :risk_history, using: :gin
  end
end
EOF

rails db:migrate
```

### Step 3: Interactive Console Demo
```ruby
# In console pane
rails console

# Create a product
product = DemoProduct.create!(
  name: "AI Assistant Device",
  price: 299.99,
  inventory_count: 50
)

# Check initial risk
puts "Initial Risk Assessment:"
puts product.risk_report.to_yaml

# Simulate external issues
Redis.current.set('supplier_api:status', 'down')
Redis.current.set('shipping:delays', 5)

# Re-check risk
product.reload
puts "\nRisk after external issues:"
puts product.risk_report.to_yaml

# Show mitigations
puts "\nSuggested Mitigations:"
product.suggested_mitigations.each_with_index do |m, i|
  puts "  #{i+1}. #{m}"
end
```

---

## Example 2: Performance Monitoring (7 minutes)

### Step 1: Add Performance-Critical Method
```ruby
# Add to DemoProduct model
cat >> app/models/demo_product.rb << 'EOF'

  def calculate_complex_discount
    with_performance_tracking do
      # Simulate complex calculation
      sleep(0.1) if Rails.env.development?
      
      base_discount = 0.1
      
      # Volume discount
      if inventory_count > 100
        base_discount += 0.05
      end
      
      # Risk-based discount
      if risk_level == :low
        base_discount += 0.03
      elsif risk_level == :high
        base_discount -= 0.05
      end
      
      # Seasonal discount
      if Date.current.month == 12
        base_discount += 0.1
      end
      
      [base_discount, 0.3].min
    end
  end
  
  def price_with_discount
    price * (1 - calculate_complex_discount)
  end
EOF
```

### Step 2: Monitor Performance
```ruby
# In console
product = DemoProduct.first

# Single execution
puts "Calculating discount..."
discount = product.calculate_complex_discount
puts "Discount: #{(discount * 100).round}%"

# Check performance metrics
metrics = JSON.parse(Redis.current.get("metrics:#{product.id}") || '{}')
puts "\nPerformance Metrics:"
puts "  Duration: #{metrics['duration']}ms"
puts "  Memory: #{metrics['memory']} objects"
puts "  Queries: #{metrics['queries']}"
```

### Step 3: Load Testing
```ruby
# Simulate load
puts "\nSimulating 100 requests..."
times = []

100.times do |i|
  start = Time.current
  product.price_with_discount
  duration = (Time.current - start) * 1000
  times << duration
  
  if i % 20 == 0
    puts "  Processed #{i} requests..."
  end
end

puts "\nPerformance Summary:"
puts "  Min: #{times.min.round(2)}ms"
puts "  Max: #{times.max.round(2)}ms"
puts "  Avg: #{(times.sum / times.length).round(2)}ms"
puts "  P95: #{times.sort[(times.length * 0.95).to_i].round(2)}ms"
```

---

## Example 3: Progressive Commit Workflow (8 minutes)

### Step 1: Make a Change
```ruby
# Add feature flag support
cat > app/models/concerns/feature_flagged.rb << 'EOF'
module FeatureFlagged
  extend ActiveSupport::Concern
  
  included do
    scope :with_feature, ->(flag) {
      where("features ? :flag", flag: flag)
    }
  end
  
  def has_feature?(flag)
    features&.include?(flag.to_s)
  end
  
  def enable_feature(flag)
    self.features ||= []
    self.features << flag.to_s unless has_feature?(flag)
    save!
  end
  
  def disable_feature(flag)
    self.features ||= []
    self.features.delete(flag.to_s)
    save!
  end
end
EOF
```

### Step 2: Test the Change
```ruby
# Quick test in console
class TestModel < ApplicationRecord
  include FeatureFlagged
end

# Would normally run proper tests
puts "Feature flag module created successfully"
```

### Step 3: Commit with Protocol
```bash
# Stage changes
git add app/models/concerns/feature_flagged.rb

# Use progressive commit
git commit -m "experiment: add feature flag support

Hypothesis: Feature flags will reduce deployment risk by 40%

Method:
- Implemented FeatureFlagged concern
- JSON array storage in features column
- Simple enable/disable interface

Results:
- ✅ Module created and tested
- ✅ No performance impact (< 1ms)
- ✅ Database migration not required (JSONB)
- ⚠️  Need to add UI for flag management

Risk Assessment:
- Feature Risk: LOW (additive only)
- Dependency Risk: NONE
- Model Risk: LOW (optional concern)
- Environmental Risk: NONE

Alternatives Considered:
- Flipper gem: Rejected - too heavy
- Redis flags: Rejected - persistence needed
- Environment vars: Rejected - not dynamic

Next Steps:
- Add admin UI for flag management
- Integrate with monitoring dashboard
- Document flag naming conventions"

# Add git notes
git notes add -m "Performance baseline: 0.8ms per flag check
Memory impact: 24 bytes per flag
Compatibility: Rails 7.0+"
```

---

## Example 4: Auto-Scaling Demo (7 minutes)

### Step 1: Create Scaling Service
```ruby
cat > app/services/demo_scaling_service.rb << 'EOF'
class DemoScalingService
  def self.analyze
    metrics = collect_metrics
    risks = assess_risks
    decision = make_decision(metrics, risks)
    
    {
      metrics: metrics,
      risks: risks,
      decision: decision,
      timestamp: Time.current
    }
  end
  
  private
  
  def self.collect_metrics
    {
      request_rate: Redis.current.get('request_rate').to_f,
      response_time_p95: Redis.current.get('response_time_p95').to_f,
      error_rate: Redis.current.get('error_rate').to_f,
      cpu_usage: rand(20..80),  # Simulated
      memory_usage: rand(40..90),  # Simulated
      active_connections: rand(100..500)  # Simulated
    }
  end
  
  def self.assess_risks
    {
      performance: calculate_performance_risk,
      capacity: calculate_capacity_risk,
      cost: calculate_cost_risk
    }
  end
  
  def self.calculate_performance_risk
    response_time = Redis.current.get('response_time_p95').to_f
    return :critical if response_time > 1000
    return :high if response_time > 500
    return :medium if response_time > 200
    :low
  end
  
  def self.calculate_capacity_risk
    cpu = rand(20..80)
    return :critical if cpu > 90
    return :high if cpu > 70
    return :medium if cpu > 50
    :low
  end
  
  def self.calculate_cost_risk
    :medium  # Simplified
  end
  
  def self.make_decision(metrics, risks)
    if risks[:performance] == :critical
      :immediate_scale_out
    elsif risks[:capacity] == :high
      :scale_out
    elsif metrics[:cpu_usage] < 20
      :scale_in
    else
      :no_action
    end
  end
end
EOF
```

### Step 2: Simulate Load Scenarios
```ruby
# In console

# Scenario 1: Normal load
puts "=== Scenario 1: Normal Load ==="
Redis.current.set('request_rate', 100)
Redis.current.set('response_time_p95', 150)
Redis.current.set('error_rate', 0.01)

analysis = DemoScalingService.analyze
puts analysis.to_yaml

# Scenario 2: High load
puts "\n=== Scenario 2: High Load ==="
Redis.current.set('request_rate', 500)
Redis.current.set('response_time_p95', 600)
Redis.current.set('error_rate', 0.05)

analysis = DemoScalingService.analyze
puts analysis.to_yaml

# Scenario 3: Critical load
puts "\n=== Scenario 3: Critical Load ==="
Redis.current.set('request_rate', 1000)
Redis.current.set('response_time_p95', 1200)
Redis.current.set('error_rate', 0.15)

analysis = DemoScalingService.analyze
puts analysis.to_yaml
```

---

## Example 5: Complete Workflow (8 minutes)

### Full Stack Demo Script
```bash
#!/bin/bash
# demo.sh - Complete Agentic Rails demo

echo "🚀 Starting Agentic Rails Demo"

# 1. Setup
echo "\n📋 Step 1: Environment Setup"
rake db:reset
rake db:seed

# 2. Start monitoring
echo "\n📊 Step 2: Starting Monitoring"
bin/monitor &
MONITOR_PID=$!

# 3. Rails console demo
echo "\n💻 Step 3: Interactive Demo"
rails runner '
  puts "Creating risk-aware products..."
  10.times do |i|
    product = DemoProduct.create!(
      name: "Product #{i}",
      price: rand(10..1000),
      inventory_count: rand(0..100)
    )
    puts "  #{product.name}: Risk level = #{product.risk_level}"
  end
  
  puts "\nSimulating high-risk event..."
  Redis.current.set("supplier_api:status", "down")
  
  DemoProduct.all.each do |product|
    product.reload
    if product.risk_level == :high
      puts "  ⚠️  #{product.name} needs attention!"
      puts "     Mitigations: #{product.suggested_mitigations.first}"
    end
  end
  
  puts "\nPerformance testing..."
  product = DemoProduct.first
  100.times { product.calculate_complex_discount }
  
  metrics = JSON.parse(Redis.current.get("metrics:#{product.id}") || "{}")
  puts "  Average response time: #{metrics["duration"]}ms"
'

# 4. Show git history
echo "\n📝 Step 4: Progressive Commit History"
git log --oneline -5
git notes show HEAD 2>/dev/null || echo "No notes on HEAD"

# 5. Cleanup
echo "\n✅ Demo Complete!"
kill $MONITOR_PID 2>/dev/null
```

---

## Tips for Live Coding

### Preparation
1. **Reset environment before demo**
   ```bash
   rake db:reset
   Redis.current.flushdb
   ```

2. **Pre-load some data**
   ```bash
   rake db:seed
   ```

3. **Have snippets ready**
   - Keep complex code in files
   - Use `cat` to display
   - Copy-paste for speed

### During the Demo

1. **Explain while typing**
   - Describe what you're building
   - Explain the "why" not just "what"
   - Point out key concepts

2. **Show immediate results**
   - Use console for instant feedback
   - Keep examples short
   - Have monitoring visible

3. **Handle errors gracefully**
   - Common errors are learning opportunities
   - Have fixes ready
   - Explain what went wrong

### Common Issues & Fixes

```ruby
# If Redis is not running
Redis.current = Redis.new(host: 'localhost', port: 6379)

# If database needs reset
rake db:drop db:create db:migrate db:seed

# If port 3000 is in use
kill -9 $(lsof -ti:3000)

# If tests fail
RAILS_ENV=test rake db:reset
```

---

## Audience Q&A Prep

### Expected Questions

**Q: What's the performance overhead?**
```ruby
# Show actual measurement
require 'benchmark'

time_with = Benchmark.measure {
  1000.times { product.with_performance_tracking { product.price } }
}.real

time_without = Benchmark.measure {
  1000.times { product.price }
}.real

puts "Overhead: #{((time_with - time_without) * 1000).round(2)}ms per 1000 calls"
```

**Q: How does it handle concurrent requests?**
```ruby
# Demonstrate thread safety
threads = 10.times.map do |i|
  Thread.new do
    product = DemoProduct.create!(name: "Thread #{i}", price: 100)
    product.risk_score
  end
end

threads.map(&:value)
puts "All threads completed successfully"
```

**Q: Can I use this with existing Rails apps?**
```ruby
# Show incremental adoption
class ExistingModel < ApplicationRecord
  # Just add the concerns
  include RiskAware
  include PerformanceMonitored
  
  # Define your risk methods
  def feature_risk; 0.1; end
  def dependency_risk; 0.2; end
  def model_risk; 0.1; end
  def environmental_risk; 0.1; end
end

puts "Existing model now has risk awareness!"
```

---

## Closing

### Summary Points
1. Risk-aware by design
2. Performance built-in
3. Progressive development
4. Universal tooling
5. Production-ready

### Call to Action
```bash
# Get started immediately
git clone https://github.com/aygp-dr/agentic-rails
cd agentic-rails
make setup
make demo

# Join the community
open https://github.com/aygp-dr/agentic-rails
```

**"Start building self-aware Rails applications today!"**