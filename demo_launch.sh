#!/bin/bash
# 三設備同步 Demo 快速啟動腳本
# 使用方法：./demo_launch.sh

set -e

echo "🚀 ClawFree 三設備同步 Demo 啟動器"
echo "=================================="
echo ""

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 啟動同步伺服器
echo -e "${BLUE}[1/4]${NC} 啟動同步伺服器..."
if pgrep -f "demo_sync_server.py" > /dev/null; then
    echo -e "${YELLOW}⚠️  同步伺服器已在運行${NC}"
else
    python3 demo_sync_server.py &
    SERVER_PID=$!
    echo -e "${GREEN}✅ 同步伺服器已啟動 (PID: $SERVER_PID)${NC}"
    sleep 2
fi

# 2. 檢查伺服器健康狀態
echo -e "${BLUE}[2/4]${NC} 檢查伺服器健康狀態..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 伺服器健康檢查通過${NC}"
else
    echo -e "${YELLOW}⚠️  伺服器健康檢查失敗，但繼續執行${NC}"
fi

# 3. 提示開啟 Flutter Apps
echo -e "${BLUE}[3/4]${NC} 準備 Flutter Apps..."
echo ""
echo "請手動執行以下步驟："
echo "  1️⃣  在 Xcode 中開啟 macOS App (Demo 模式)"
echo "  2️⃣  在 Xcode 中開啟 iPhone App (Demo 模式)"
echo "  3️⃣  等待兩個 App 都連線到 WebSocket 伺服器"
echo ""
read -p "按 Enter 繼續..."

# 4. 提示開啟 Watch App
echo -e "${BLUE}[4/4]${NC} 準備 Watch App..."
echo ""
echo "請手動執行以下步驟："
echo "  1️⃣  在 Xcode 中開啟 Watch App (模擬器)"
echo "  2️⃣  點擊 'Start Demo' 按鈕"
echo "  3️⃣  觀察三個設備的同步效果"
echo ""
echo -e "${GREEN}✅ 準備完成！開始錄製 Demo${NC}"
echo ""

# 顯示測試指令
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 手動測試指令（模擬 Watch 發送訊息）："
echo ""
echo "curl -X POST http://localhost:8080/message \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"text\":\"Plan a 3-day foodie trip to Tokyo\",\"isUser\":true,\"source\":\"watch\",\"timestamp\":\"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'\"}'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 提供停止腳本
echo "📌 完成 Demo 後，執行以下指令停止伺服器："
echo "   pkill -f demo_sync_server.py"
echo ""
