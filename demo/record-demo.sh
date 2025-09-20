#!/bin/bash
# Record Agentic Rails demo with asciinema and convert to GIF

set -e

echo "🎬 Agentic Rails Demo Recording Script"
echo "======================================="
echo

# Configuration
CAST_FILE="demo/agentic-rails-demo.cast"
GIF_FILE="demo/agentic-rails-demo.gif"
SVG_FILE="demo/agentic-rails-demo.svg"

# Recording settings
ROWS=30
COLS=120
IDLE_LIMIT=2

echo "📹 Starting asciinema recording..."
echo "   Output: $CAST_FILE"
echo "   Terminal: ${COLS}x${ROWS}"
echo "   Idle limit: ${IDLE_LIMIT}s"
echo
echo "Press Ctrl+D when done recording"
echo "-----------------------------------"
sleep 2

# Start recording with asciinema
asciinema rec \
    --title "Agentic Rails: Risk-Aware Development Framework" \
    --idle-time-limit $IDLE_LIMIT \
    --cols $COLS \
    --rows $ROWS \
    --overwrite \
    $CAST_FILE \
    --command "./demo/demo-sequence.sh"

echo
echo "✅ Recording complete!"
echo

# Convert to GIF using agg
echo "🎨 Converting to animated GIF..."
agg \
    --cols $COLS \
    --rows $ROWS \
    --theme monokai \
    --font-family "JetBrains Mono,Monaco,monospace" \
    --font-size 14 \
    --line-height 1.4 \
    --speed 1.5 \
    $CAST_FILE \
    $GIF_FILE

echo "✅ GIF created: $GIF_FILE"
echo

# Also create SVG for better quality
echo "🎨 Converting to SVG..."
svg-term \
    --cast $CAST_FILE \
    --out $SVG_FILE \
    --width $COLS \
    --height $ROWS \
    --theme monokai \
    2>/dev/null || echo "Note: svg-term not installed, skipping SVG generation"

# Generate stats
if [ -f "$GIF_FILE" ]; then
    SIZE=$(du -h "$GIF_FILE" | cut -f1)
    echo
    echo "📊 Recording Statistics:"
    echo "   GIF Size: $SIZE"
    echo "   Duration: $(asciinema play --speed 999999 $CAST_FILE 2>&1 | grep -oE '[0-9]+:[0-9]+' | tail -1)"
    echo "   Location: $GIF_FILE"
fi

echo
echo "🚀 Demo recording complete!"
echo
echo "To play back the recording:"
echo "  asciinema play $CAST_FILE"
echo
echo "To upload to asciinema.org:"
echo "  asciinema upload $CAST_FILE"
echo
echo "To embed GIF in README:"
echo "  ![Agentic Rails Demo]($GIF_FILE)"