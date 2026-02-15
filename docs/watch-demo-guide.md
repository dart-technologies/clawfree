# Apple Watch Demo 功能指南

## 架構概覽（方案 B：透過 iPhone 轉發）

```
Apple Watch ──WatchConnectivity──► iPhone (Flutter) ──► AI Backend
    │                                    │
    ├─ 按鈕指令（plan_a_trip/create_agent）
    ├─ 錄音 + Groq Whisper STT
    └─ Demo 模式（自動播放腳本）
```

## 功能

### 手錶端
1. **兩個快捷按鈕**
   - 🤖 Create Agent → 發送 `{"type": "command", "command": "create_agent"}`
   - ✈️ Plan Trip → 發送 `{"type": "command", "command": "plan_a_trip"}`

2. **語音錄音 + STT**（`isDemoMode = false` 時）
   - 點擊麥克風按鈕開始錄音
   - 再次點擊停止錄音
   - 自動送到 Groq Whisper API 轉錄（中英文）
   - 轉錄文字顯示在手錶螢幕
   - 發送到 iPhone：`{"type": "text", "text": "轉錄內容"}`

3. **Demo 模式**（`isDemoMode = true`，預設）
   - 自動播放三段腳本 + 打字動畫
   - 適合錄製 Demo 影片

### iPhone 端
- 接收手錶 `command` + `params` → genUI 自動填入選項 + 送出 AI 指令
- 選項對照表自動映射（如 "Tokyo" → "Tokyo, Japan"）
- 接收手錶 `text` → 顯示在輸入框 + 自動送出
- 接收手錶 `voice_command` → 舊格式相容

### Watch ↔ iPhone 選項對照表

| Watch 顯示 | iPhone genUI |
|-----------|-------------|
| Tokyo | Tokyo, Japan |
| Kyoto | Kyoto, Japan |
| Osaka | Osaka, Japan |
| Seoul | Seoul, South Korea |
| Bangkok | Bangkok, Thailand |
| Opus 4.6 | Claude Opus 4.6 |
| Sonnet 4.5 | Claude Sonnet 4.5 |
| Gemini Pro | Gemini Pro |

## 編譯

```bash
# 驗證編譯（不需簽名）
make build-watch

# 編譯到實體裝置（需要 Xcode 簽名設定）
make build-watch-device

# 或用 Xcode 開啟
open ios/Runner.xcworkspace
# 選 WatchCompanion scheme → 連接的 Apple Watch → Run
```

## 實體裝置測試步驟

1. **前置條件**
   - Apple Watch 已配對 iPhone
   - iPhone 已安裝 Clawfree app
   - Xcode 已設定開發者帳號 + 簽名

2. **安裝到手錶**
   - Xcode → Scheme: WatchCompanion
   - Destination: 你的 Apple Watch
   - Run (⌘R)

3. **測試流程**
   - 手錶上按 "Create Agent" → iPhone 收到指令
   - 手錶上按 "Plan Trip" → iPhone 收到指令
   - 手錶上點麥克風 → 錄音 → 再點停止 → 看轉錄結果
   - 確認 iPhone 畫面有顯示收到的文字

4. **常見問題**
   - "iPhone not reachable" → 確認 iPhone app 在前景
   - 錄音失敗 → 確認已授權麥克風權限
   - STT 失敗 → 檢查網路連線 + Groq API Key

## Demo 影片腳本

### 場景一：語音建立 Agent（30s）
1. 手錶顯示主畫面，Connected 綠燈亮
2. 點擊麥克風 → "Create a trip planner agent"
3. 文字出現在手錶螢幕
4. iPhone 同時顯示收到的指令 + AI 開始回應

### 場景二：按鈕快速操作 + genUI 同步（20s）
1. 手錶按 "Plan Trip" 按鈕
2. 進入旅行規劃流程（選城市 → 天數 → 景點）
3. 點擊 "Start Planning" → 發送 `command: plan_a_trip` + `params: {city, days, attractions}`
4. iPhone genUI 自動顯示對應選項（如 Tokyo, Japan + 3 days）

### 場景四：Create Agent genUI 同步（20s）
1. 手錶按 "Create Agent" 按鈕
2. 選模型（Sonnet 4.5）→ 選技能 → 確認
3. 點擊 "Create" → 發送 `command: create_agent` + `params: {model, name, skills}`
4. iPhone genUI 自動顯示 Claude Sonnet 4.5 + 技能列表

### 場景三：中文語音指令（20s）
1. 點擊麥克風 → 說中文 "幫我規劃三天東京行程"
2. Groq Whisper 轉錄顯示在手錶
3. iPhone 收到中文指令

## 檔案結構

```
ios/WatchCompanion/
├── WatchCompanionApp.swift      # App 入口
├── PulseMonitorView.swift       # 主畫面（語音 + 按鈕）
├── AudioRecorder.swift          # ✨ 真實錄音（AVAudioRecorder）
├── GroqSTTService.swift         # ✨ Groq Whisper STT
├── ConnectivityProvider.swift   # WatchConnectivity 橋接
├── WatchTTSService.swift        # 語音合成
├── AgentConfigView.swift        # 建 Agent 互動流程
├── TripPlannerView.swift        # 旅行規劃互動流程
├── SpeechRecognizer.swift       # 系統 dictation（備用）
└── Info.plist

ios/Runner/
└── AppDelegate.swift            # ✨ 新增 command/text 訊息處理

lib/src/core/
└── watch_bridge.dart            # ✨ 新增 command/text 事件類型

lib/src/ui/
└── chat_screen.dart             # ✨ 新增 _handleWatchCommand
```

## Groq API 配置

API Key 硬編碼在 `GroqSTTService.swift` 中（Demo 用途）。
正式版應改為從 iPhone 端動態傳入或使用 Keychain。

```bash
# 查看當前 API Key
openclaw config get env.vars.GROQ_API_KEY
```
