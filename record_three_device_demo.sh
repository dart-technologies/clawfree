#!/bin/bash
# 錄製 MyChat 三設備 Demo（iPhone + Watch + macOS）with DEMO_MODE

set -e
cd "$(dirname "$0")"

echo "🎬 MyChat 三設備 Demo 錄製"
echo "=========================="
echo ""

# Configuration
DEMO_DURATION=50  # seconds (稍長於 watch demo 的 45.58s)
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

# Boot Watch (optional - if needed)
WATCH_ID=$(xcrun simctl list devices available | grep "Apple Watch Series 10" | head -1 | awk -F'[()]' '{print $2}')
if [ -n "$WATCH_ID" ]; then
    xcrun simctl boot "$WATCH_ID" 2>/dev/null || echo "   Watch already booted"
    echo "✅ Apple Watch Series 10: $WATCH_ID"
fi
echo ""

sleep 3

echo "🚀 Step 2: Launch apps with DEMO_MODE..."

# Launch iPhone app with DEMO_MODE
echo "   Launching iPhone app (DEMO_MODE)..."
nohup flutter run -d "$IPHONE_ID" --dart-define=DEMO_MODE=true > "/tmp/clawfree_iphone_${TIMESTAMP}.log" 2>&1 &
IPHONE_PID=$!
echo "   ⏱️  Waiting for iPhone app to initialize..."
sleep 10

echo "✅ iPhone app launched (PID: $IPHONE_PID)"
echo ""

echo "📹 Step 3: Start recording iPhone..."
echo "   Recording for ${DEMO_DURATION} seconds..."

IPHONE_VIDEO="${OUTPUT_DIR}/iphone_demo_${TIMESTAMP}.mp4"
xcrun simctl io "$IPHONE_ID" recordVideo --codec=h264 --force "$IPHONE_VIDEO" &
IPHONE_REC_PID=$!

echo "✅ Recording started"
echo "   iPhone: PID $IPHONE_REC_PID → $IPHONE_VIDEO"
echo ""

# Wait for demo to complete
echo "⏱️  Demo running... (${DEMO_DURATION}s)"
echo "   請在 iPhone 模擬器中執行 Demo 腳本（12 步旅遊規劃流程）"
echo ""
sleep "$DEMO_DURATION"

echo ""
echo "🛑 Step 4: Stop recording..."
kill -SIGINT "$IPHONE_REC_PID" 2>/dev/null || true
sleep 2

echo ""
echo "🛑 Step 5: Stop apps..."
kill "$IPHONE_PID" 2>/dev/null || true
sleep 2

echo ""
echo "✅ iPhone recording complete!"
echo ""
echo "📁 File saved: $IPHONE_VIDEO"
ls -lh "$IPHONE_VIDEO" 2>/dev/null || echo "   (File may take a moment to finalize)"
echo ""
echo "📝 Log available at: /tmp/clawfree_iphone_${TIMESTAMP}.log"
echo ""
echo "---"
echo "📱 Next: Record macOS Demo"
echo "   Run: ./record_macos_demo.sh"
