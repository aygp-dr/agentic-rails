#!/bin/bash
# Automated demo sequence for asciinema recording

# Configuration
TYPING_SPEED=0.05
PAUSE_SHORT=1
PAUSE_MEDIUM=2
PAUSE_LONG=3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Function to simulate typing
type_command() {
    echo -n -e "${GREEN}$ ${NC}"
    echo -n "$1" | while IFS= read -r -n1 char; do
        echo -n "$char"
        sleep $TYPING_SPEED
    done
    echo
    sleep $PAUSE_SHORT
    eval "$1"
    sleep $PAUSE_MEDIUM
}

# Function to show comment
show_comment() {
    echo -e "${CYAN}# $1${NC}"
    sleep $PAUSE_SHORT
}

# Function to show banner
show_banner() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════╗
║         AGENTIC RAILS FRAMEWORK           ║
║     Risk-Aware • Performance-Optimized    ║
║          Progressive • Universal          ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    sleep $PAUSE_LONG
}

# Start demo
show_banner

# Part 1: Introduction
show_comment "Welcome to Agentic Rails - Self-Aware Rails Applications"
sleep $PAUSE_MEDIUM

show_comment "Let's explore risk-aware development..."
echo

# Part 2: Risk-Aware Models
show_comment "Creating a risk-aware product model"
type_command "cat app/models/concerns/risk_aware.rb | head -20"

show_comment "Each model tracks 4 risk dimensions"
type_command "grep 'def.*_risk' app/models/product.rb"

echo
show_comment "Let's see risk assessment in action"
cat << 'RUBY' > /tmp/risk_demo.rb
product = Product.new(name: 'AI Assistant', price: 299.99, inventory_count: 5)
puts "Product: #{product.name}"
puts "Initial Risk Score: #{product.risk_score.round(2)}"
puts "Risk Level: #{product.risk_level}"
puts ""
puts "Risk Breakdown:"
puts "  Feature Risk: #{product.feature_risk}"
puts "  Dependency Risk: #{product.dependency_risk}"
puts "  Model Risk: #{product.model_risk}"
puts "  Environmental Risk: #{product.environmental_risk}"
puts ""
puts "Suggested Mitigations:"
product.suggested_mitigations.each { |m| puts "  • #{m}" }
RUBY

type_command "rails runner /tmp/risk_demo.rb"

# Part 3: Performance Monitoring
echo
show_comment "Performance monitoring is built into every method"
cat << 'RUBY' > /tmp/perf_demo.rb
product = Product.first || Product.create!(name: 'Demo', price: 99)

# Track performance of a method
result = product.with_performance_tracking do
  sleep 0.1  # Simulate work
  product.calculate_discount
end

puts "Discount calculated: #{(result * 100).round}%"
puts ""
puts "Performance metrics stored in Redis:"
metrics = JSON.parse(Redis.current.get("product:#{product.id}:metrics") || '{}')
puts "  Duration: #{metrics['duration']}ms"
puts "  Memory: #{metrics['memory_allocated']} objects"
puts "  Timestamp: #{metrics['timestamp']}"
RUBY

type_command "rails runner /tmp/perf_demo.rb"

# Part 4: Progressive Commit Protocol
echo
show_comment "Every commit is an experiment with hypothesis and results"
type_command "git log --oneline -3"

show_comment "Let's look at a commit with full context"
type_command "git show --stat HEAD~1 | head -20"

# Part 5: Universal Build System
echo
show_comment "Universal build system works everywhere"
type_command "make help | head -15"

show_comment "Platform detection and smart dependency management"
type_command "grep -A5 'UNAME_S' Makefile"

# Part 6: Testing Strategy
echo
show_comment "Comprehensive testing with property-based tests"
type_command "find test -name '*_test.rb' | wc -l"

show_comment "Property-based testing ensures correctness"
type_command "grep -A10 'property \"risk scores' test/property/risk_calculation_property_test.rb"

# Part 7: Live Risk Monitoring
echo
show_comment "Real-time risk monitoring dashboard"
cat << 'BASH' > /tmp/monitor.sh
#!/bin/bash
for i in {1..5}; do
    clear
    echo -e "\033[1;36m═══ RISK MONITORING DASHBOARD ═══\033[0m"
    echo
    echo "$(date +'%H:%M:%S')"
    echo
    echo "System Risk Levels:"
    echo "  Feature Risk:      ████████░░ HIGH (0.8)"
    echo "  Dependency Risk:   ██████░░░░ MEDIUM (0.6)"
    echo "  Model Risk:        ████░░░░░░ LOW (0.4)"
    echo "  Environmental:     ██░░░░░░░░ LOW (0.2)"
    echo
    echo "Overall Risk Score: 0.65 [MEDIUM]"
    echo
    if [ $i -eq 3 ]; then
        echo -e "\033[1;31m⚠️  ALERT: Supplier API Down!\033[0m"
        echo "Suggested Mitigation: Enable fallback provider"
    fi
    echo
    echo "Active Mitigations:"
    echo "  ✅ Rate limiting enabled"
    echo "  ✅ Circuit breaker active"
    echo "  ✅ Cache warmed"
    sleep 2
done
BASH

chmod +x /tmp/monitor.sh
type_command "/tmp/monitor.sh"

# Part 8: Closing
echo
show_banner
echo -e "${GREEN}✅ Demo Complete!${NC}"
echo
echo -e "${YELLOW}Get Started:${NC}"
echo "  git clone https://github.com/aygp-dr/agentic-rails"
echo "  cd agentic-rails"
echo "  make setup"
echo
echo -e "${CYAN}Learn more at: github.com/aygp-dr/agentic-rails${NC}"
echo
sleep $PAUSE_LONG