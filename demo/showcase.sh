#!/bin/bash
# Agentic Rails Feature Showcase

clear

# Banner
echo "╔═══════════════════════════════════════════╗"
echo "║         AGENTIC RAILS FRAMEWORK           ║"
echo "║     Risk-Aware • Performance-Optimized    ║"
echo "╚═══════════════════════════════════════════╝"
echo
sleep 2

# Show directory structure
echo "📁 Framework Structure:"
ls -la app/models/concerns/
echo
sleep 2

# Show risk-aware module
echo "🎯 Risk-Aware Module:"
echo "-------------------"
head -20 app/models/concerns/risk_aware.rb
echo
sleep 3

# Run the risk demo
echo "🚀 Running Risk Assessment Demo..."
echo "================================="
ruby demo/standalone_risk.rb
echo
sleep 3

# Show commit protocol
echo "📝 Progressive Commit Protocol:"
echo "------------------------------"
echo "Each commit includes hypothesis and results:"
echo
cat .github/COMMIT_PROTOCOL.md | head -25
echo
sleep 3

# Show Makefile
echo "🔧 Universal Build System:"
echo "------------------------"
echo "Works on FreeBSD, macOS, and Linux:"
make help | head -10
echo
sleep 2

echo "✅ Demo Complete!"
echo
echo "Get started:"
echo "  git clone https://github.com/aygp-dr/agentic-rails"
echo "  cd agentic-rails"
echo "  make setup"