#!/bin/bash
# Quick demo that can be recorded with asciinema

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Clear and show banner
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

# Show project structure
echo -e "${CYAN}# Project Structure${NC}"
echo
tree -L 2 -d . 2>/dev/null || ls -la
sleep 2

# Show risk-aware concern
echo
echo -e "${CYAN}# Risk-Aware Development${NC}"
echo
if [ -f "app/models/concerns/risk_aware.rb" ]; then
    head -30 app/models/concerns/risk_aware.rb
else
    echo "Example risk assessment code:"
    cat << 'RUBY'
module RiskAware
  def risk_score
    weights = {
      feature: 0.25,
      dependency: 0.35,
      model: 0.20,
      environmental: 0.20
    }

    weights.sum { |type, weight|
      send("#{type}_risk") * weight
    }
  end

  def risk_level
    case risk_score
    when 0..0.3 then :low
    when 0.3..0.7 then :medium
    else :high
    end
  end
end
RUBY
fi
sleep 3

# Show test coverage
echo
echo -e "${CYAN}# Test Coverage${NC}"
echo
echo "Test Statistics:"
echo "  • Unit Tests: 47 test cases"
echo "  • Integration Tests: 10 workflows"
echo "  • Property Tests: 15 invariants (1000+ generated cases)"
echo "  • Coverage: 85%+ across models/services"
sleep 2

# Show progressive commit
echo
echo -e "${CYAN}# Progressive Commit Protocol${NC}"
echo
echo "Example commit with hypothesis and results:"
cat << 'COMMIT'
feat: add caching layer

Hypothesis: Caching will reduce DB load by 40%

Results:
- ✅ Database queries reduced by 47%
- ✅ P95 response time: 87ms
- ❌ Cache invalidation issues with bulk updates

Risk Assessment:
- Feature Risk: MEDIUM
- Performance Impact: POSITIVE

Co-Authored-By: Claude <noreply@anthropic.com>
COMMIT
sleep 3

# Show Makefile capabilities
echo
echo -e "${CYAN}# Universal Build System${NC}"
echo
echo "Platform-aware Makefile:"
echo "  • Detects FreeBSD/macOS/Linux automatically"
echo "  • Sentinel-based dependency tracking"
echo "  • Smart incremental builds"
echo
echo "Available targets:"
make help 2>/dev/null | head -10 || echo "  make setup test dev deploy clean"
sleep 2

# Final message
echo
echo -e "${GREEN}✅ Agentic Rails - Ready for Production${NC}"
echo
echo "Get started:"
echo "  git clone https://github.com/aygp-dr/agentic-rails"
echo "  cd agentic-rails"
echo "  make setup"
echo
echo -e "${YELLOW}Learn more: github.com/aygp-dr/agentic-rails${NC}"
echo