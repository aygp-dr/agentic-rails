# Agentic Rails - Demo Materials

This directory contains demonstration materials for the Agentic Rails framework.

## Contents

### Presentations & Scripts

1. **PRESENTATION.md** - 25+ slide presentation covering all framework features
2. **VIDEO_SCRIPT.md** - 5-minute video demo script with production notes
3. **INTERACTIVE_DEMO.md** - 15-minute hands-on demonstration guide
4. **LIVE_CODING_EXAMPLES.md** - 30-45 minute live coding session examples

### Recording Tools

- **tmux-demo.sh** - Automated tmux session setup for demonstrations
- **demo-sequence.sh** - Step-by-step automated demo sequence
- **quick-demo.sh** - Quick demo script for recordings
- **record-demo.sh** - asciinema recording and GIF conversion script

### Recordings

- **agentic-rails.cast** - asciinema recording file
- **agentic-rails.gif** - Animated GIF demo

## Quick Demo

Run the quick demo:
```bash
./demo/quick-demo.sh
```

## Recording a Demo

Record with asciinema:
```bash
asciinema rec --title "My Demo" --command "./demo/quick-demo.sh" demo.cast
```

Convert to GIF:
```bash
agg --theme monokai --font-size 14 demo.cast demo.gif
```

## tmux Session Demo

Launch the full tmux demo environment:
```bash
./demo/tmux-demo.sh
```

This creates a 4-pane layout with:
- Editor (top-left)
- Rails Console (bottom-left)
- Rails Server (top-right)
- Monitoring Dashboard (bottom-right)

## Live Coding Sessions

The live coding examples demonstrate:
1. Risk-aware model creation
2. Performance monitoring implementation
3. Progressive commit workflow
4. Auto-scaling service
5. Complete integration demo

## Presentation Flow

1. **Opening** - Problem statement
2. **Core Concepts** - Risk awareness, performance, commits
3. **Live Demo** - Interactive examples
4. **Results** - Metrics and improvements
5. **Call to Action** - Getting started

## Tips for Presenters

### Preparation
- Reset database: `rake db:reset`
- Clear Redis: `Redis.current.flushdb`
- Pre-load data: `rake db:seed`

### During Demo
- Explain concepts before code
- Show immediate results
- Keep examples concise
- Have backup snippets ready

### Common Issues
- Redis not running: Start with `redis-server`
- Port conflicts: Kill with `lsof -ti:3000 | xargs kill -9`
- Database issues: `rake db:drop db:create db:migrate`

## Resources

- [Main README](../README.md)
- [Progressive Commit Guide](../docs/PROGRESSIVE_COMMIT_PROTOCOL_GUIDE.md)
- [GitHub Repository](https://github.com/aygp-dr/agentic-rails)