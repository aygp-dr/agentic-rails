#!/bin/bash
# Run Agentic Rails in tmux session

# Add gem binaries to PATH
export PATH=$HOME/.local/share/gem/ruby/3.3/bin:$PATH

# Kill any existing session
tmux kill-session -t agentic-rails 2>/dev/null || true

# Create new tmux session with 4 panes
tmux new-session -d -s agentic-rails -n main

# Create layout:
# ┌─────────────┬──────────────┐
# │   Server    │   Console    │
# ├─────────────┼──────────────┤
# │   Logs      │   Monitor    │
# └─────────────┴──────────────┘

tmux split-window -h -t agentic-rails:main
tmux split-window -v -t agentic-rails:main.0
tmux split-window -v -t agentic-rails:main.2

# Setup database in pane 0 (will become Server)
tmux send-keys -t agentic-rails:main.0 "echo '🚀 Setting up Rails...'" C-m
tmux send-keys -t agentic-rails:main.0 "export PATH=$HOME/.local/share/gem/ruby/3.3/bin:\$PATH" C-m

# Check if we need Rails
tmux send-keys -t agentic-rails:main.0 "which rails || gem install rails" C-m
sleep 2

# Create simple Rails app if needed
tmux send-keys -t agentic-rails:main.0 "if [ ! -f 'config/application.rb' ]; then" C-m
tmux send-keys -t agentic-rails:main.0 "  echo 'Creating Rails application...'" C-m
tmux send-keys -t agentic-rails:main.0 "  rails new . --database=postgresql --skip-git --skip-bundle" C-m
tmux send-keys -t agentic-rails:main.0 "fi" C-m
sleep 3

# Start Rails server in pane 0
tmux send-keys -t agentic-rails:main.0 "echo '🚀 Starting Rails Server on port 3000...'" C-m
tmux send-keys -t agentic-rails:main.0 "rails server || ruby -run -e httpd . -p 3000" C-m

# Rails console in pane 1
tmux send-keys -t agentic-rails:main.1 "echo '💻 Rails Console'" C-m
tmux send-keys -t agentic-rails:main.1 "export PATH=$HOME/.local/share/gem/ruby/3.3/bin:\$PATH" C-m
sleep 1
tmux send-keys -t agentic-rails:main.1 "rails console || irb" C-m

# Logs in pane 2
tmux send-keys -t agentic-rails:main.2 "echo '📝 Rails Logs'" C-m
tmux send-keys -t agentic-rails:main.2 "if [ -f 'log/development.log' ]; then" C-m
tmux send-keys -t agentic-rails:main.2 "  tail -f log/development.log" C-m
tmux send-keys -t agentic-rails:main.2 "else" C-m
tmux send-keys -t agentic-rails:main.2 "  echo 'Waiting for logs...'; touch log/development.log 2>/dev/null; tail -f log/development.log 2>/dev/null || watch -n1 'ls -la'" C-m
tmux send-keys -t agentic-rails:main.2 "fi" C-m

# Monitor in pane 3
tmux send-keys -t agentic-rails:main.3 "echo '📊 System Monitor'" C-m
tmux send-keys -t agentic-rails:main.3 "while true; do" C-m
tmux send-keys -t agentic-rails:main.3 "  clear" C-m
tmux send-keys -t agentic-rails:main.3 "  echo '═══ AGENTIC RAILS MONITOR ═══'" C-m
tmux send-keys -t agentic-rails:main.3 "  echo" C-m
tmux send-keys -t agentic-rails:main.3 "  date +'%H:%M:%S'" C-m
tmux send-keys -t agentic-rails:main.3 "  echo" C-m
tmux send-keys -t agentic-rails:main.3 "  echo 'Rails Status:'" C-m
tmux send-keys -t agentic-rails:main.3 "  ps aux | grep -E '(rails|puma|ruby)' | grep -v grep | head -3" C-m
tmux send-keys -t agentic-rails:main.3 "  echo" C-m
tmux send-keys -t agentic-rails:main.3 "  echo 'Port 3000:'" C-m
tmux send-keys -t agentic-rails:main.3 "  sockstat -4 -l | grep 3000 || netstat -an | grep 3000 || echo 'Not listening yet'" C-m
tmux send-keys -t agentic-rails:main.3 "  echo" C-m
tmux send-keys -t agentic-rails:main.3 "  echo 'Risk Features:'" C-m
tmux send-keys -t agentic-rails:main.3 "  if [ -f 'app/models/concerns/risk_aware.rb' ]; then" C-m
tmux send-keys -t agentic-rails:main.3 "    echo '✅ Risk-Aware module loaded'" C-m
tmux send-keys -t agentic-rails:main.3 "  else" C-m
tmux send-keys -t agentic-rails:main.3 "    echo '⚠️  Risk-Aware module not found'" C-m
tmux send-keys -t agentic-rails:main.3 "  fi" C-m
tmux send-keys -t agentic-rails:main.3 "  if [ -f 'app/models/concerns/performance_monitored.rb' ]; then" C-m
tmux send-keys -t agentic-rails:main.3 "    echo '✅ Performance monitoring loaded'" C-m
tmux send-keys -t agentic-rails:main.3 "  else" C-m
tmux send-keys -t agentic-rails:main.3 "    echo '⚠️  Performance monitoring not found'" C-m
tmux send-keys -t agentic-rails:main.3 "  fi" C-m
tmux send-keys -t agentic-rails:main.3 "  sleep 3" C-m
tmux send-keys -t agentic-rails:main.3 "done" C-m

# Attach to session
echo "✅ tmux session 'agentic-rails' created with 4 panes:"
echo "  0: Rails Server (port 3000)"
echo "  1: Rails Console"
echo "  2: Rails Logs"
echo "  3: System Monitor"
echo
echo "Attaching to session..."
tmux attach-session -t agentic-rails