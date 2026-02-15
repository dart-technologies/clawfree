#!/bin/bash
# Run Clawfree demo - Step by step guide

set -e
cd "$(dirname "$0")"

echo "🚀 Clawfree Three-Device Demo Setup"
echo "=================================="
echo ""

# Check which devices are booted
IPHONE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | grep "Booted" | awk -F'[()]' '{print $2}' | head -1)
WATCH_ID=$(xcrun simctl list devices available | grep "Apple Watch Series 10" | grep "Booted" | awk -F'[()]' '{print $2}' | head -1)

if [ -z "$IPHONE_ID" ]; then
    echo "❌ iPhone 17 Pro is not booted."
    echo "   Please open Xcode → Window → Devices and Simulators → Boot iPhone 17 Pro"
    exit 1
fi

if [ -z "$WATCH_ID" ]; then
    echo "❌ Apple Watch Series 10 is not booted."
    echo "   Please pair and boot Apple Watch Series 10 with iPhone 17 Pro"
    exit 1
fi

echo "✅ iPhone 17 Pro: $IPHONE_ID (Booted)"
echo "✅ Apple Watch Series 10: $WATCH_ID (Booted)"
echo ""
echo "📝 Manual Steps:"
echo ""
echo "1️⃣  Open Terminal Tab 1:"
echo "    cd /Users/roypctw/dev/clawfree"
echo "    flutter run -d macos"
echo ""
echo "2️⃣  Open Terminal Tab 2:"
echo "    cd /Users/roypctw/dev/clawfree"
echo "    flutter run -d $IPHONE_ID"
echo ""
echo "3️⃣  Watch app will auto-launch when iPhone app starts"
echo "    Demo will auto-start after 2 seconds!"
echo ""
echo "4️⃣  Use QuickTime Player to record:"
echo "    • iPhone screen: File → New Movie Recording → Select iPhone simulator"
echo "    • macOS screen: File → New Screen Recording"
echo "    • Watch screen: (included in iPhone recording)"
echo ""
echo "🎬 Expected Flow:"
echo "   Watch: User speaks → AI responds (TTS + earcons)"
echo "   iPhone: Receives message → Shows in chat"
echo "   macOS: Syncs chat history"
echo ""
echo "⚠️  Note: Auto-demo mode is ENABLED (isAutoDemoMode = true)"
echo "    Demo starts automatically 2 seconds after Watch app launches."
echo ""
echo "Press ENTER to continue with automated launch (experimental)..."
read

echo ""
echo "🚀 Attempting automated launch..."
echo ""

# Try to launch in background
echo "📱 Launching macOS app in background..."
nohup flutter run -d macos > /tmp/clawfree_macos.log 2>&1 &
MACOS_PID=$!
echo "   PID: $MACOS_PID"
sleep 8

echo "📱 Launching iPhone app in background..."
nohup flutter run -d "$IPHONE_ID" > /tmp/clawfree_iphone.log 2>&1 &
IPHONE_PID=$!
echo "   PID: $IPHONE_PID"
sleep 8

echo ""
echo "✅ Apps should be launching..."
echo "   Check simulator windows for app screens."
echo "   Watch for auto-demo to start in 2 seconds."
echo ""
echo "📹 Start screen recording NOW if you haven't already!"
echo ""
echo "Press ENTER when demo is complete to stop apps..."
read

echo ""
echo "🛑 Stopping apps..."
kill $MACOS_PID 2>/dev/null || true
kill $IPHONE_PID 2>/dev/null || true

echo ""
echo "✅ Demo complete!"
echo "📁 Logs saved to:"
echo "   /tmp/clawfree_macos.log"
echo "   /tmp/clawfree_iphone.log"
