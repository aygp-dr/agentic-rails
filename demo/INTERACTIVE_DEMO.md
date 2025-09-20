# Agentic Rails - Interactive Demo Script

## 🎯 Demo Overview
**Duration**: 15 minutes
**Audience**: Developers, DevOps Engineers, Technical Leaders
**Key Message**: Risk-aware development with built-in performance monitoring

---

## 📋 Pre-Demo Checklist

```bash
# Ensure everything is ready
make clean
make setup
docker-compose up -d

# Open terminals
tmux new-session -s demo
```

---

## Demo 1: Risk-Aware Development (5 min)

### 1.1 Show Risk Assessment in Action

```bash
# Start Rails console
rails console
```

```ruby
# Create a product and watch risk assessment
product = Product.new(name: "Demo Product", price: 99.99)
puts "Initial risk: #{product.risk_score}"

# Simulate high-risk conditions
Redis.current.set('supplier_api:status', 'down')
Redis.current.set('shipping:delays', 5)

product.save!
puts "Risk after external issues: #{product.risk_score}"
puts "Risk level: #{product.risk_level}"
puts "Suggested mitigations:"
product.suggested_mitigations.each { |m| puts "  - #{m}" }
```

### 1.2 Real-time Risk Monitoring

```bash
# In a new terminal, start monitoring
bin/monitor
```

```ruby
# Back in console, trigger risk events
10.times do
  product = Product.create!(
    name: "Product #{rand(1000)}",
    price: rand(10..1000),
    inventory_count: rand(0..10)
  )
  puts "Created #{product.name} with risk: #{product.risk_level}"
  sleep 1
end
```

**Key Points**:
- Automatic risk calculation
- Real-time monitoring
- Actionable mitigation suggestions

---

## Demo 2: Progressive Commit Protocol (3 min)

### 2.1 Show Commit with Hypothesis

```bash
# Make a change
echo "# Demo change" >> README.md

# Use progressive commit
bin/progressive-commit commit
```

Walk through the prompts:
- Hypothesis: "Adding documentation will improve onboarding"
- Results: "✅ Documentation added"
- Risk Assessment: Feature=LOW, Dependency=NONE

### 2.2 View Commit History

```bash
# Show commit with full context
git log -1 --format=full

# Show git notes
git notes show HEAD

# Generate development journey
bin/progressive-commit document
open DEVELOPMENT_JOURNEY.md
```

**Key Points**:
- Every commit has hypothesis & results
- Risk assessment built into workflow
- Complete traceability

---

## Demo 3: Universal Build System (3 min)

### 3.1 Platform Detection

```bash
# Run onboarding script
./bin/onboard
```

Show output:
- Platform detection (FreeBSD/macOS/Linux)
- Dependency checking
- Environment validation

### 3.2 Makefile with Sentinels

```bash
# Show sentinel-based dependency tracking
make clean
ls -la .make-sentinels/  # Empty

make deps
ls -la .make-sentinels/  # Shows completed tasks

# Run again - skips completed
time make deps  # Much faster

# Touch Gemfile to invalidate
touch Gemfile
make deps  # Reruns Ruby deps only
```

**Key Points**:
- Works on FreeBSD, macOS, Linux
- Smart dependency tracking
- Incremental builds

---

## Demo 4: Performance Monitoring (4 min)

### 4.1 Method-Level Tracking

```ruby
# In Rails console
product = Product.first

# Watch performance tracking
product.with_performance_tracking do
  # Simulate slow operation
  sleep 0.1
  product.calculate_discount
end

# Check metrics in Redis
Redis.current.lrange('response_times', 0, 5)
```

### 4.2 Live Dashboard

```bash
# Terminal 1: Generate load
rails runner "
  100.times do
    Product.available.includes(:reviews).to_a
    sleep 0.1
  end
"

# Terminal 2: Watch monitoring
bin/monitor
```

Show dashboard updating:
- Request rate
- Response times (P95)
- Cache hit rate
- System resources

### 4.3 Automatic Scaling Decision

```ruby
# In console
ScalingService.analyze_and_scale

# Check what it recommends
metrics = ScalingService.collect_metrics
risks = ScalingService.assess_scaling_risks(metrics)

puts "Metrics: #{metrics}"
puts "Risks: #{risks}"
puts "Should scale? #{ScalingService.should_scale?(metrics, risks)}"
```

**Key Points**:
- Real-time performance metrics
- Automatic scaling decisions
- Risk-based thresholds

---

## 🎬 Demo Finale: Full Stack in Action

### Terminal Layout with tmux

```bash
# Load the development layout
tmux source-file .tmux/dev-layout.conf
```

Show 5 panes:
1. **Editor**: Live code editing
2. **Server**: Rails server logs
3. **Console**: Interactive Rails console
4. **Tests**: Continuous testing
5. **Monitor**: Performance metrics

### Make a Change with Full Workflow

1. **Edit** product.rb - add a method
2. **Test** runs automatically
3. **Monitor** shows performance
4. **Commit** with hypothesis
5. **Deploy** with risk assessment

```bash
# The complete flow
vim app/models/product.rb
# Add: def trending?; view_count > 100; end

# Tests run in guard pane

# Commit with protocol
git add -A
git commit -m "feat: add trending product detection

Hypothesis: Trending detection will improve recommendations

Results:
- ✅ Method added
- ✅ Tests passing

Risk Assessment:
- Feature Risk: LOW
- Dependency Risk: NONE
- Performance Impact: MINIMAL
- Security Risk: NONE"

# Deploy with risk check
bin/deploy staging
```

---

## 📊 Closing Stats

Show the achievements:

```bash
# Project statistics
echo "=== Agentic Rails Stats ==="
echo "Commits: $(git rev-list --count HEAD)"
echo "Tests: $(find test -name "*_test.rb" -exec grep "test \"" {} \; | wc -l)"
echo "Risk Assessments: $(grep -r "risk_score" app | wc -l)"
echo "Performance Tracking: $(grep -r "with_performance" app | wc -l)"
echo ""
echo "Platform Support:"
echo "  ✓ FreeBSD"
echo "  ✓ macOS"
echo "  ✓ Linux"
echo "  ✓ Docker"
```

---

## 🎯 Key Takeaways

1. **Risk-Aware by Design** - Every model knows its risk
2. **Performance Built-in** - Not bolted on later
3. **Progressive Development** - Every commit has purpose
4. **Universal Tooling** - Works everywhere
5. **Observable by Default** - Know what's happening

---

## 💬 Q&A Preparation

### Common Questions:

**Q: How does this differ from standard Rails?**
A: We've added risk assessment and performance monitoring as first-class concerns, integrated at the model level.

**Q: What's the performance overhead?**
A: ~5ms for risk calculation, ~2ms for performance tracking. Monitoring is async.

**Q: Can I adopt this incrementally?**
A: Yes! Each component (risk, performance, protocol) can be adopted independently.

**Q: Does it work with existing Rails apps?**
A: Yes, the concerns can be added to any Rails 7+ application.

---

## 🚀 Call to Action

```bash
# Get started now
git clone https://github.com/aygp-dr/agentic-rails
cd agentic-rails
make setup
make dev

# Join the community
open https://github.com/aygp-dr/agentic-rails
```

"Start building risk-aware, performance-optimized Rails applications today!"