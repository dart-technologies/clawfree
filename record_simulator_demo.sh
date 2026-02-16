#!/bin/bash
# Auto-record Clawfree simulator demo - iPhone + Watch + macOS

set -e
cd "$(dirname "$0")"

echo "🎬 Clawfree Simulator Demo Auto-Recording"
echo "========================================="
echo ""

# Configuration
DEMO_DURATION=60  # seconds
OUTPUT_DIR="demo_videos"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$OUTPUT_DIR"

echo "📱 Step 1: Boot simulators..."
# Boot iPhone
IPHONE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | awk -F'[()]' '{print $2}')
if [ -z "$IPHONE_ID" ]; then
    echo "❌ iPhone 17 Pro not found"
    exit 1
fi

xcrun simctl boot "$IPHONE_ID" 2>/dev/null || echo "   iPhone already booted"
echo "✅ iPhone 17 Pro: $IPHONE_ID"

# Boot Watch
WATCH_ID=$(xcrun simctl list devices available | grep "Apple Watch Series 10" | head -1 | awk -F'[()]' '{print $2}')
if [ -z "$WATCH_ID" ]; then
    echo "❌ Apple Watch Series 10 not found"
    exit 1
fi

xcrun simctl boot "$WATCH_ID" 2>/dev/null || echo "   Watch already booted"
echo "✅ Apple Watch Series 10: $WATCH_ID"
echo ""

sleep 3

echo "🚀 Step 2: Launch apps..."

# Launch macOS app in background
echo "   Launching macOS app..."
nohup flutter run -d macos > "/tmp/clawfree_macos_${TIMESTAMP}.log" 2>&1 &
MACOS_PID=$!
sleep 8

# Launch iPhone app in background
echo "   Launching iPhone app..."
nohup flutter run -d "$IPHONE_ID" > "/tmp/clawfree_iphone_${TIMESTAMP}.log" 2>&1 &
IPHONE_PID=$!
sleep 8

echo "✅ Apps launched (macOS PID: $MACOS_PID, iPhone PID: $IPHONE_PID)"
echo ""

echo "📹 Step 3: Start recording..."
echo "   Recording for ${DEMO_DURATION} seconds..."

# Record iPhone (includes Watch in paired mode)
IPHONE_VIDEO="${OUTPUT_DIR}/iphone_${TIMESTAMP}.mp4"
xcrun simctl io "$IPHONE_ID" recordVideo --codec=h264 --force "$IPHONE_VIDEO" &
IPHONE_REC_PID=$!

# Record Watch separately
WATCH_VIDEO="${OUTPUT_DIR}/watch_${TIMESTAMP}.mp4"
xcrun simctl io "$WATCH_ID" recordVideo --codec=h264 --force "$WATCH_VIDEO" &
WATCH_REC_PID=$!

echo "✅ Recording started"
echo "   iPhone: PID $IPHONE_REC_PID → $IPHONE_VIDEO"
echo "   Watch: PID $WATCH_REC_PID → $WATCH_VIDEO"
echo ""

# Wait for demo to complete
echo "⏱️  Demo running... (${DEMO_DURATION}s)"
sleep "$DEMO_DURATION"

echo ""
echo "🛑 Step 4: Stop recording..."
kill -SIGINT "$IPHONE_REC_PID" 2>/dev/null || true
kill -SIGINT "$WATCH_REC_PID" 2>/dev/null || true
sleep 2

echo ""
echo "🛑 Step 5: Stop apps..."
kill "$MACOS_PID" 2>/dev/null || true
kill "$IPHONE_PID" 2>/dev/null || true
sleep 2

echo ""
echo "✅ Recording complete!"
echo ""
echo "📁 Files saved:"
echo "   iPhone: $IPHONE_VIDEO"
echo "   Watch: $WATCH_VIDEO"
echo ""
echo "📊 File info:"
ls -lh "$IPHONE_VIDEO" "$WATCH_VIDEO" 2>/dev/null || echo "   (Files may take a moment to finalize)"
echo ""
echo "💡 Next steps:"
echo "   1. Open videos to verify recording quality"
echo "   2. Use video editor to combine iPhone + Watch + macOS screens"
echo "   3. Add titles/annotations if needed"
echo ""
echo "📝 Logs available at:"
echo "   /tmp/clawfree_macos_${TIMESTAMP}.log"
echo "   /tmp/clawfree_iphone_${TIMESTAMP}.log"
