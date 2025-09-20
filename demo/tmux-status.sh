#!/bin/bash
# Check status of Agentic Rails tmux session

echo "═══════════════════════════════════════════════"
echo "     AGENTIC RAILS TMUX SESSION STATUS"
echo "═══════════════════════════════════════════════"
echo

# Check if session exists
if tmux has-session -t agentic-rails 2>/dev/null; then
    echo "✅ Session 'agentic-rails' is running"
    echo

    # List panes
    echo "📊 Active Panes:"
    tmux list-panes -t agentic-rails -F "  Pane #{pane_index}: #{pane_width}x#{pane_height} (#{pane_current_command})"
    echo

    # Check web server
    echo "🌐 Web Server Status:"
    if sockstat -4 -l | grep -q 3000; then
        echo "  ✅ Server running on port 3000"
        echo "  URL: http://localhost:3000"
    else
        echo "  ⚠️  No server on port 3000"
    fi
    echo

    # Check features
    echo "🎯 Framework Features:"
    [ -f "app/models/concerns/risk_aware.rb" ] && echo "  ✅ Risk-Aware module" || echo "  ❌ Risk-Aware module"
    [ -f "app/models/concerns/performance_monitored.rb" ] && echo "  ✅ Performance Monitoring" || echo "  ❌ Performance Monitoring"
    [ -f ".github/COMMIT_PROTOCOL.md" ] && echo "  ✅ Progressive Commit Protocol" || echo "  ❌ Progressive Commit Protocol"
    [ -f "Makefile" ] && echo "  ✅ Universal Build System" || echo "  ❌ Universal Build System"
    echo

    echo "💡 To attach to the session:"
    echo "  tmux attach-session -t agentic-rails"
    echo
    echo "🔧 Pane Layout:"
    echo "  ┌─────────────┬──────────────┐"
    echo "  │  0: Server  │  1: Console  │"
    echo "  ├─────────────┼──────────────┤"
    echo "  │  2: Logs    │  3: Monitor  │"
    echo "  └─────────────┴──────────────┘"
else
    echo "❌ Session 'agentic-rails' is not running"
    echo
    echo "To start the session, run:"
    echo "  ./demo/run-rails-tmux.sh"
fi

echo
echo "═══════════════════════════════════════════════"