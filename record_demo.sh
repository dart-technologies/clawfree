#!/bin/bash
# 自动录制三设备 Demo
# 布局：左边 macOS (70%) | 右上 Watch | 右下 iPhone

set -e

echo "🎬 准备录制三设备 Demo..."

# 获取屏幕尺寸
SCREEN_WIDTH=$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2}' | head -1)
SCREEN_HEIGHT=$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $4}' | head -1)

echo "📐 屏幕尺寸: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

# 计算窗口位置和大小
MACOS_WIDTH=$((SCREEN_WIDTH * 70 / 100))
MACOS_HEIGHT=$((SCREEN_HEIGHT - 100))
MACOS_X=0
MACOS_Y=50

RIGHT_WIDTH=$((SCREEN_WIDTH - MACOS_WIDTH))
RIGHT_HEIGHT=$((SCREEN_HEIGHT - 100))

WATCH_WIDTH=$RIGHT_WIDTH
WATCH_HEIGHT=$((RIGHT_HEIGHT / 2))
WATCH_X=$MACOS_WIDTH
WATCH_Y=50

IPHONE_WIDTH=$RIGHT_WIDTH
IPHONE_HEIGHT=$((RIGHT_HEIGHT / 2))
IPHONE_X=$MACOS_WIDTH
IPHONE_Y=$((50 + WATCH_HEIGHT))

echo "📱 窗口布局："
echo "  macOS: ${MACOS_WIDTH}x${MACOS_HEIGHT} at (${MACOS_X},${MACOS_Y})"
echo "  Watch: ${WATCH_WIDTH}x${WATCH_HEIGHT} at (${WATCH_X},${WATCH_Y})"
echo "  iPhone: ${IPHONE_WIDTH}x${IPHONE_HEIGHT} at (${IPHONE_X},${IPHONE_Y})"

# 使用 AppleScript 排列窗口
osascript <<EOF
tell application "System Events"
    -- 排列 Clawfree macOS 窗口
    tell process "clawfree"
        try
            set position of window 1 to {$MACOS_X, $MACOS_Y}
            set size of window 1 to {$MACOS_WIDTH, $MACOS_HEIGHT}
        end try
    end tell
    
    -- 排列 iPhone 模拟器
    tell process "Simulator"
        try
            -- iPhone 窗口（通常是第一个）
            set position of window 1 to {$IPHONE_X, $IPHONE_Y}
            delay 0.5
            
            -- Apple Watch 窗口（通常是第二个）
            if (count of windows) > 1 then
                set position of window 2 to {$WATCH_X, $WATCH_Y}
            end if
        end try
    end tell
end tell
EOF

echo "✅ 窗口已排列"
sleep 2

# 开始录制（使用 screencapture）
OUTPUT_FILE="/Users/roypctw/dev/clawfree/demo_videos/three_devices_demo_$(date +%Y%m%d_%H%M%S).mov"
echo "🎥 开始录制到: $OUTPUT_FILE"

# 计算录制区域
RECORD_X=0
RECORD_Y=50
RECORD_WIDTH=$SCREEN_WIDTH
RECORD_HEIGHT=$((SCREEN_HEIGHT - 100))

echo "📹 录制区域: ${RECORD_WIDTH}x${RECORD_HEIGHT} at (${RECORD_X},${RECORD_Y})"

# 启动录制（后台）
# 注意：screencapture 只能截图，需要用 QuickTime 或其他工具录制视频
# 这里我们用 ffmpeg（如果安装了）

if command -v ffmpeg &> /dev/null; then
    echo "使用 ffmpeg 录制..."
    
    # 获取屏幕 device
    SCREEN_DEVICE=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "Capture screen" | head -1 | sed 's/.*\[\([0-9]\)\].*/\1/')
    
    # 开始录制（25 秒，覆盖整个 Demo）
    ffmpeg -f avfoundation -i "${SCREEN_DEVICE}:none" -t 30 -r 30 "$OUTPUT_FILE" &
    FFMPEG_PID=$!
    
    echo "🎥 录制进程 PID: $FFMPEG_PID"
    sleep 3
    
    # 重启 Demo（hot reload）
    echo "🔄 重启 Demo..."
    # 给 macOS app 发送 'r' (hot reload)
    osascript -e 'tell application "Terminal" to activate'
    osascript -e 'tell application "System Events" to keystroke "r"'
    
    sleep 2
    
    # 给 iPhone app 发送 'r' (hot reload)
    osascript -e 'tell application "System Events" to keystroke "r"'
    
    echo "⏳ 等待 Demo 完成（30 秒）..."
    sleep 30
    
    # 停止录制
    kill $FFMPEG_PID 2>/dev/null || true
    
    echo "✅ 录制完成！"
    echo "📹 视频文件: $OUTPUT_FILE"
    
else
    echo "❌ 未安装 ffmpeg，无法自动录制"
    echo "请手动录制："
    echo "1. 按 Cmd+Shift+5 打开系统截屏工具"
    echo "2. 选择 '录制选定部分'"
    echo "3. 框选整个屏幕或三个窗口区域"
    echo "4. 开始录制"
    echo ""
    echo "窗口已排列好，准备开始！"
fi
