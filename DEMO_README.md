# 三設備同步 Demo - 快速指引

**狀態：** ✅ 架構驗證成功，待錄製 Demo  
**專案：** ClawFree - MyChat 三設備同步  
**更新：** 2026-02-16

---

## 🚀 快速開始（3 分鐘）

```bash
cd /Users/roypctw/dev/clawfree
./demo_launch.sh
```

然後按照腳本提示：
1. 開啟 macOS App (Demo 模式)
2. 開啟 iPhone App (Demo 模式)
3. 開啟 Watch App (模擬器)
4. 點擊 Watch 的 "Start Demo"
5. 觀察三設備同步效果 🎉

---

## 📚 文件索引

| 文件 | 說明 |
|------|------|
| [`docs/方案A_完成報告.md`](docs/方案A_完成報告.md) | **主報告** - 完整的任務執行記錄 |
| [`docs/三設備同步測試報告_20260216.md`](docs/三設備同步測試報告_20260216.md) | **技術文件** - 架構、流程、排查 |
| [`demo_launch.sh`](demo_launch.sh) | **啟動腳本** - 一鍵啟動環境 |
| [`test_watch_message.sh`](test_watch_message.sh) | **測試腳本** - 手動測試同步 |

---

## 🎯 Demo 目標

展示 **Watch → WebSocket Server → iPhone/macOS** 的真正即時同步：

```
Watch App 執行 12 步 Demo
  ↓
4 則訊息發送到 Server
  ↓
Server 廣播給 iPhone + macOS
  ↓
iPhone/macOS 即時顯示 + genUI 觸發
```

---

## ✅ 已完成

1. ✅ Swift 代碼已實現 HTTP POST（`ConnectivityProvider.swift`）
2. ✅ Python WebSocket 伺服器已準備（`demo_sync_server.py`）
3. ✅ Flutter 客戶端已實現（`lib/src/core/demo_sync_client.dart`）
4. ✅ 編譯 Watch App 成功
5. ✅ 測試訊息廣播成功（2 個客戶端）

---

## 📋 待執行

1. 📋 執行 `demo_launch.sh` 啟動環境
2. 📋 錄製三設備同步視頻
3. 📋 發送視頻到 Telegram Topic 9062

---

## 🎬 Demo 12 步流程

| 步驟 | Watch 顯示 | 發送到手機 |
|------|-----------|-----------|
| 2 | 👤 "Plan a 3-day foodie trip to Tokyo" | ✅ |
| 3 | 🤖 思考中... | ❌ |
| 4 | 🤖 "I've created a Travel Concierge Agent..." | ❌ |
| 5 | 👤 "OK, confirm" | ✅ |
| 6 | 🤖 ✅ "Agent saved successfully!" | ❌ |
| 7 | 🤖 💡 "Perfect! I'll start planning..." | ❌ |
| 8 | 👤 "Generate Itinerary" | ✅ |
| 8b | 🤖 思考中... | ❌ |
| 9 | 🤖 "Here's your Tokyo foodie adventure..." | ❌ |
| 10 | 👤 "Book Trip" | ✅ |
| 11 | 🤖 "Booking your trip now..." | ❌ |
| 12 | ✅ Demo 完成 | - |

**總計：** 4 則訊息會同步到 iPhone/macOS

---

## 🧪 測試同步機制

手動發送測試訊息（模擬 Watch）：

```bash
./test_watch_message.sh
```

預期回應：
```json
{"status": "ok", "broadcast_count": 2}
```

---

## 🛠️ 問題排查

### 伺服器無法啟動
```bash
pkill -f demo_sync_server.py
python3 demo_sync_server.py
```

### 訊息未廣播
```bash
curl http://localhost:8080/health
```

應該顯示 `ws_clients: 2`（iPhone + macOS）

---

## 📦 關鍵檔案

```
clawfree/
├── ios/WatchCompanion/
│   ├── DemoScriptRunner.swift          # Watch Demo 邏輯
│   └── ConnectivityProvider.swift      # HTTP POST 實現
├── lib/src/core/
│   └── demo_sync_client.dart           # Flutter WebSocket 客戶端
├── demo_sync_server.py                 # WebSocket 伺服器
├── demo_launch.sh                      # ✨ 快速啟動
└── test_watch_message.sh               # ✨ 測試工具
```

---

## 🎥 錄製要點

1. **同時錄製** - 三個設備並排展示
2. **關鍵時刻** - 標註訊息發送與接收的時間點
3. **genUI 觸發** - 展示 Travel Agent 和 Itinerary 畫面
4. **TTS 播放** - 確認語音同步正常

---

**預估時間：** 20-30 分鐘（包含錄製與後製）

**完成後：** 發送視頻到 Telegram Topic 9062

**負責人：** 酪梨管家 ✅ 架構驗證完成，等待 Roy 錄製 Demo
