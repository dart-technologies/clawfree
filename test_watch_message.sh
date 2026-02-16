#!/bin/bash
# 模擬 Watch App 發送訊息到同步伺服器

echo "📱 模擬 Watch 發送訊息..."

curl -X POST http://localhost:8080/message \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Plan a 3-day foodie trip to Tokyo",
    "isUser": true,
    "source": "watch",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'

echo -e "\n✅ 訊息已發送"
echo "檢查 iPhone/macOS App 是否即時收到訊息"
