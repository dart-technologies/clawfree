#!/bin/bash

# record_window.sh - Records specifically the clawfree macOS window.
# Usage: ./scripts/record_window.sh [output_filename] [audio_device_index]

OUTPUT_FILE="${1:-demo_recording.mp4}"
AUDIO_INDEX="${2:-1}"
WINDOW_NAME="clawfree" 
WIDTH=1280
HEIGHT=840 # Increased to capture full window + title bar perfectly

echo "Starting E2E test in background..."
# Run flutter test directly to avoid make overhead and get a direct PID
flutter test integration_test/demo_driver.dart -d macos --timeout 5x > /tmp/demo_test_output.log 2>&1 &
TEST_PID=$!

echo "Waiting for $WINDOW_NAME window to appear..."
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
  WIN_EXIST=$(osascript -e 'tell application "System Events" to exists process "'"$WINDOW_NAME"'"' 2>/dev/null)
  if [ "$WIN_EXIST" == "true" ]; then
    break
  fi
  if ! kill -0 $TEST_PID 2>/dev/null; then
    # Sometimes the test runner process exits but the app is still launching
    # Let's wait a bit more if it's very early
    if [ $WAITED -lt 5 ]; then
       sleep 1
       WAITED=$((WAITED+1))
       continue
    fi
    echo "Test failed to start or crashed. Check /tmp/demo_test_output.log"
    exit 1
  fi
  sleep 1
  WAITED=$((WAITED+1))
done

echo "Positioning and resizing window..."
# Move window to a safe offset (e.g., {300, 100}) to clear the Dock on the left
osascript -e 'tell application "System Events" to tell process "'"$WINDOW_NAME"'"
  set position of window 1 to {300, 100}
  set size of window 1 to {1280, 840}
  set frontmost to true
end tell'

# Wait a moment for window to settle
sleep 1

# --- FIX: Dynamic Coordinate Capture ---
# Read back the ACTUAL position in case the system adjusted it (due to Dock/Menu bar)
WIN_POS=$(osascript -e 'tell application "System Events" to tell process "'"$WINDOW_NAME"'" to get position of window 1')
X=$(echo $WIN_POS | cut -d',' -f1 | tr -d ' ')
Y=$(echo $WIN_POS | cut -d',' -f2 | tr -d ' ')

echo "Window is at logical coordinates: $X, $Y"

# Account for Retina/HiDPI scaling
PHYS_W=$(system_profiler SPDisplaysDataType | grep "Resolution" | head -1 | grep -oE '[0-9]+' | head -1)
LOGIC_W=$(system_profiler SPDisplaysDataType | grep "UI Looks like" | head -1 | grep -oE '[0-9]+' | head -1)
SCALE=$((PHYS_W / LOGIC_W))

CROP_W=$((WIDTH * SCALE))
CROP_H=$((HEIGHT * SCALE))
CROP_X=$((X * SCALE))
CROP_Y=$((Y * SCALE)) # Capture from the very top of the window to prevent cutoff

echo "Window is at logical coordinates: $X, $Y"
echo "Detected display scale factor: $SCALE"
echo "Final Pixel Crop: ${CROP_W}x${CROP_H} at ${CROP_X},${CROP_Y}"

echo "IMPORTANT: Ensure your System Output is set to 'BlackHole 2ch' for audio!"
sleep 2

# Start ffmpeg.
echo "Starting ffmpeg recording..."
# --- Video input ---
# -framerate 24: Cinematic rate, 20% less CPU than 30fps
# -capture_cursor 0: Skip cursor compositing (free CPU reduction)
# -thread_queue_size 8192 + -rtbufsize 512M: Massive buffer headroom
# --- Audio input ---
# Separate input with its own thread queue to prevent video starvation
# --- Filters ---
# crop → scale: Capture at Retina, crop window, downscale to 1x (75% less encoder work)
# aresample async=1000: Smooth clock drift without aggressive per-sample correction
# --- Encoding ---
# -realtime true: videotoolbox hardware realtime path
#
# NOTE: Do NOT add -fps_mode cfr — it rewrites the video PTS timeline which
# causes aresample to see massive A/V drift and fill audio with silence.
# Do NOT add highpass/lowpass/ac filters — they destabilize the audio path.
nice -n -20 ffmpeg -y \
  -probesize 100M -analyzeduration 100M \
  -thread_queue_size 8192 -f avfoundation -framerate 24 -capture_cursor 0 -rtbufsize 512M -i "0" \
  -thread_queue_size 8192 -f avfoundation -rtbufsize 100M -i ":$AUDIO_INDEX" \
  -vf "crop=$CROP_W:$CROP_H:$CROP_X:$CROP_Y,scale=$WIDTH:$HEIGHT" \
  -vcodec h264_videotoolbox -realtime true -b:v 8M \
  -acodec aac -ar 48000 -b:a 192k \
  -af "aresample=async=1000:min_hard_comp=0.100000:first_pts=0" \
  -map 0:v -map 1:a \
  "$OUTPUT_FILE" &
FFMPEG_PID=$!

# Wait for test to finish
wait $TEST_PID
TEST_EXIT_CODE=$?

# Stop ffmpeg
kill -INT $FFMPEG_PID
wait $FFMPEG_PID

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "Recording complete: $OUTPUT_FILE"
else
  echo "Test failed with exit code $TEST_EXIT_CODE. Recording saved."
fi
