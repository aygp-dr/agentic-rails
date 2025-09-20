#!/bin/bash
# Agentic Rails - tmux Demo Script for asciinema recording

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to type with delays (simulating human typing)
type_command() {
    echo -n "$1" | while IFS= read -r -n1 char; do
        echo -n "$char"
        sleep 0.05
    done
    echo
    sleep 0.5
}

# Function to show a banner
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
    sleep 2
}

# Kill any existing tmux sessions
tmux kill-session -t agentic-demo 2>/dev/null || true

# Start new tmux session
tmux new-session -d -s agentic-demo -n main

# Create the layout: 4 panes
# ┌─────────────┬──────────────┐
# │   Editor    │    Server    │
# ├─────────────┼──────────────┤
# │   Console   │   Monitor    │
# └─────────────┴──────────────┘

tmux split-window -h -t agentic-demo:main
tmux split-window -v -t agentic-demo:main.0
tmux split-window -v -t agentic-demo:main.2

# Rename panes for clarity
tmux select-pane -t agentic-demo:main.0 -T "Editor"
tmux select-pane -t agentic-demo:main.1 -T "Console"
tmux select-pane -t agentic-demo:main.2 -T "Server"
tmux select-pane -t agentic-demo:main.3 -T "Monitor"

# Start Rails server in pane 2
tmux send-keys -t agentic-demo:main.2 "echo '🚀 Rails Server'" C-m
tmux send-keys -t agentic-demo:main.2 "rails server" C-m

# Start monitoring in pane 3
tmux send-keys -t agentic-demo:main.3 "echo '📊 Risk & Performance Monitor'" C-m
tmux send-keys -t agentic-demo:main.3 "while true; do clear; echo -e '\\033[1;36m═══ RISK MONITORING DASHBOARD ═══\\033[0m'; echo; date +'%H:%M:%S'; echo; echo 'Feature Risk:    ████████░░ HIGH'; echo 'Dependency Risk: ██████░░░░ MEDIUM'; echo 'Performance:     ████░░░░░░ GOOD'; echo 'Security Risk:   ██░░░░░░░░ LOW'; echo; echo -e '\\033[1;33m⚠️  Supplier API: DOWN\\033[0m'; echo; sleep 2; done" C-m

# Focus on editor pane
tmux select-pane -t agentic-demo:main.0

# Demo Part 1: Create Risk-Aware Model
tmux send-keys -t agentic-demo:main.0 "clear" C-m
tmux send-keys -t agentic-demo:main.0 "echo '📝 Creating Risk-Aware Product Model...'" C-m
sleep 1

tmux send-keys -t agentic-demo:main.0 "cat > app/models/risk_demo.rb << 'EOF'
class RiskDemo < ApplicationRecord
  include RiskAware
  include PerformanceMonitored

  def feature_risk
    return 0.9 if created_at > 7.days.ago
    0.2
  end

  def dependency_risk
    Redis.current.get('supplier_api:status') == 'down' ? 0.8 : 0.1
  end

  def model_risk
    inventory_count < 10 ? 0.6 : 0.2
  end

  def environmental_risk
    Date.current.month == 12 ? 0.7 : 0.1
  end
end
EOF" C-m

sleep 2

# Switch to console pane
tmux select-pane -t agentic-demo:main.1
tmux send-keys -t agentic-demo:main.1 "rails console" C-m
sleep 3

# Demo Part 2: Interactive Risk Assessment
tmux send-keys -t agentic-demo:main.1 "# Create a product and assess risk" C-m
tmux send-keys -t agentic-demo:main.1 "product = Product.new(name: 'AI Assistant', price: 299.99)" C-m
sleep 1

tmux send-keys -t agentic-demo:main.1 "puts product.risk_report" C-m
sleep 2

tmux send-keys -t agentic-demo:main.1 "# Simulate external issues" C-m
tmux send-keys -t agentic-demo:main.1 "Redis.current.set('supplier_api:status', 'down')" C-m
sleep 1

tmux send-keys -t agentic-demo:main.1 "product.reload" C-m
tmux send-keys -t agentic-demo:main.1 "puts \"Risk Level: #{product.risk_level}\"" C-m
tmux send-keys -t agentic-demo:main.1 "puts \"Mitigations: #{product.suggested_mitigations.join(', ')}\"" C-m
sleep 2

# Demo Part 3: Performance Monitoring
tmux send-keys -t agentic-demo:main.1 "# Performance monitoring example" C-m
tmux send-keys -t agentic-demo:main.1 "product.with_performance_tracking { product.calculate_discount }" C-m
sleep 1

tmux send-keys -t agentic-demo:main.1 "metrics = JSON.parse(Redis.current.get(\"metrics:#{product.id}\") || '{}')" C-m
tmux send-keys -t agentic-demo:main.1 "puts \"Duration: #{metrics['duration']}ms\"" C-m
sleep 2

# Demo Part 4: Progressive Commit
tmux select-pane -t agentic-demo:main.0
tmux send-keys -t agentic-demo:main.0 "clear" C-m
tmux send-keys -t agentic-demo:main.0 "echo '📝 Progressive Commit Protocol Example'" C-m
sleep 1

tmux send-keys -t agentic-demo:main.0 "git add -A" C-m
tmux send-keys -t agentic-demo:main.0 "git commit -m 'feat: add risk-aware demo model

Hypothesis: Risk assessment will reduce incidents by 40%

Results:
- ✅ Risk scoring implemented
- ✅ Real-time monitoring active
- ✅ Mitigation suggestions working

Risk Assessment:
- Feature Risk: LOW
- Performance Impact: MINIMAL'" C-m

sleep 3

# Demo Part 5: Show Universal Build
tmux select-pane -t agentic-demo:main.0
tmux send-keys -t agentic-demo:main.0 "clear" C-m
tmux send-keys -t agentic-demo:main.0 "echo '🔧 Universal Build System'" C-m
sleep 1

tmux send-keys -t agentic-demo:main.0 "make help" C-m
sleep 2

tmux send-keys -t agentic-demo:main.0 "echo 'Platform: FreeBSD'" C-m
tmux send-keys -t agentic-demo:main.0 "make deps" C-m
sleep 2

# Final: Show all panes working together
tmux select-pane -t agentic-demo:main.1
tmux send-keys -t agentic-demo:main.1 "# All systems operational!" C-m
tmux send-keys -t agentic-demo:main.1 "puts '✅ Risk-Aware Development Active'" C-m
tmux send-keys -t agentic-demo:main.1 "puts '✅ Performance Monitoring Running'" C-m
tmux send-keys -t agentic-demo:main.1 "puts '✅ Progressive Commits Enabled'" C-m
tmux send-keys -t agentic-demo:main.1 "puts '✅ Universal Build Ready'" C-m

sleep 2

# Attach to the session
tmux attach-session -t agentic-demo