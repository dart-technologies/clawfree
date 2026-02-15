# 🎬 Clawfree Watch Mock Demo — 模擬器演示指南

## 架構

```
⌚ Watch 模擬器 (SwiftUI)
   ↓ HTTP POST localhost:8888/command
🖥️ Mock Server (Python)
   ↓ GET /poll
📱 iPhone 模擬器 (Flutter)
   → 顯示 genUI (Plan Trip / Create Agent)
   → 自動送出到 AI 聊天
```

## 快速開始

### 1. 啟動 Mock Server

```bash
cd /Users/roypctw/dev/clawfree
python3 scripts/mock_server.py
```

看到 `🚀 Mock server running on http://localhost:8888` 即成功。

### 2. 啟動 iPhone 模擬器

```bash
cd /Users/roypctw/dev/clawfree
flutter run -d "iPhone 16 Pro"
```

iPhone app 會自動每 500ms 輪詢 mock server。

### 3. 啟動 Watch 模擬器

在 Xcode 開啟 `ios/Runner.xcworkspace`：
1. 選擇 `WatchCompanion` scheme
2. 選擇 Apple Watch 模擬器
3. Build & Run (⌘R)

### 4. 演示流程

在 Watch 模擬器上：
1. 點擊 **「Simulate Recording」** 按鈕（橘色）
2. 選擇指令：
   - **Plan a Trip** → iPhone 顯示城市選擇 genUI
   - **Create an Agent** → iPhone 顯示 Agent 建構 genUI  
   - **Ask a Question** → iPhone 直接送出文字
3. Watch 播放錄音動畫 → 打字機效果 → 發送
4. iPhone 自動接收 → 顯示 genUI 面板 → 送出到 AI

## 演示腳本（30 秒版本）

1. **[0-5s]** 展示 Watch 主畫面（Clawfree logo + 麥克風）
2. **[5-10s]** 點擊 "Simulate Recording" → 選擇 "Plan a Trip"
3. **[10-18s]** Watch 動畫：錄音波形 → 打字 "Plan a 3 day trip to Tokyo" → 送出
4. **[18-25s]** 切到 iPhone：genUI 面板出現（城市選擇卡片）
5. **[25-30s]** 在 genUI 選擇城市 → 確認 → AI 回應

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `scripts/mock_server.py` | HTTP mock server（Watch↔iPhone 通訊橋樑）|
| `ios/WatchCompanion/MockConnectivityProvider.swift` | Watch 端 HTTP 發送（取代 WCSession）|
| `ios/WatchCompanion/CommandPickerView.swift` | 模擬錄音指令選單 |
| `ios/WatchCompanion/PulseMonitorView.swift` | 主 Watch UI（新增 Simulate 按鈕）|
| `lib/src/ui/widgets/trip_planner_genui.dart` | Plan Trip genUI 面板 |
| `lib/src/ui/widgets/agent_builder_genui.dart` | Create Agent genUI 面板 |
| `lib/src/ui/chat_screen.dart` | iPhone 端 mock polling + genUI 顯示 |

## 注意事項

- Mock server 必須在 Watch 和 iPhone 模擬器**之前**啟動
- 兩個模擬器共用 localhost，所以 HTTP 通訊直接可用
- `#if targetEnvironment(simulator)` 確保 mock 代碼不影響真機
- genUI 面板目前是靜態卡片，可後續接入真實 AI
