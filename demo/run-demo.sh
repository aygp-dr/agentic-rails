#!/bin/bash
# Run Agentic Rails Demo - Manual flow for asciinema recording

echo "╔═══════════════════════════════════════════╗"
echo "║         AGENTIC RAILS FRAMEWORK           ║"
echo "║     Risk-Aware • Performance-Optimized    ║"
echo "║          Progressive • Universal          ║"
echo "╚═══════════════════════════════════════════╝"
echo

echo "This demo shows:"
echo "1. Risk-aware development with real-time assessment"
echo "2. Performance monitoring built into every model"
echo "3. Progressive commit protocol for traceable development"
echo "4. Universal build system (FreeBSD/macOS/Linux)"
echo

echo "Press Enter to start the demo..."
read

# Show framework structure
echo "📁 Framework Structure:"
ls -la app/models/concerns/ 2>/dev/null || echo "  (Rails concerns for risk and performance)"
echo

# Run the standalone risk demo
if [ -f "demo/standalone_risk.rb" ]; then
    echo "🎯 Running Risk Assessment Demo..."
    ruby demo/standalone_risk.rb
else
    echo "⚠️  Demo script not found. Here's what it would show:"
    echo
    echo "Product: AI Assistant"
    echo "Inventory: 5 units"
    echo
    echo "Risk Breakdown:"
    echo "  Feature Risk:       ███░░░░░░░ (0.3)"
    echo "  Dependency Risk:    ████████░░ (0.8)"
    echo "  Model Risk:         ████░░░░░░ (0.4)"
    echo "  Environmental Risk: ██░░░░░░░░ (0.2)"
    echo
    echo "Overall Risk Score: 0.48"
    echo "Risk Level: MEDIUM"
    echo
    echo "Suggested Mitigations:"
    echo "  1. Increase inventory levels"
fi

echo
echo "📝 Progressive Commit Protocol:"
echo "Recent commits with hypothesis and results:"
git log --oneline -3 2>/dev/null || echo "  (Each commit includes hypothesis, results, and risk assessment)"

echo
echo "🔧 Universal Build System:"
echo "Platform: $(uname -s)"
echo "Available make targets:"
make help 2>/dev/null | head -5 || echo "  setup, test, dev, deploy, clean"

echo
echo "═══════════════════════════════════════════════"
echo "✅ Demo Complete!"
echo
echo "Get started:"
echo "  git clone https://github.com/aygp-dr/agentic-rails"
echo "  cd agentic-rails"
echo "  make setup"
echo
echo "Learn more: github.com/aygp-dr/agentic-rails"