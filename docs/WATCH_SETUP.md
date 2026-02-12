# Clawfree watchOS App 設定指南

## 前置準備

watchOS source 檔案已準備好在 `ios/ClawfreeWatch/`：
- `ClawfreeWatchApp.swift` — App 進入點
- `ContentView.swift` — 主畫面（語音錄製 + 訊息列表）
- `WatchSessionManager.swift` — WatchConnectivity 管理
- `AudioRecorder.swift` — 錄音功能
- `WatchMessage.swift` — 訊息 Model
- `Assets.xcassets/` — App Icon
- `Info.plist` — Watch app 設定

## Xcode 手動加入 Watch Target

### 1. 建立 Target
1. 開啟 `ios/Runner.xcworkspace`
2. **File → New → Target**
3. 選擇 **watchOS → App**
4. 設定：
   - **Product Name**: `ClawfreeWatch`
   - **Bundle Identifier**: `com.rollbytes.clawfree.watchkitapp`
   - **Language**: Swift
   - **Watch App**: SwiftUI（不勾 Include Notification Scene）
   - **Embed in Companion App**: Runner
5. **Team ID**: `3HUWM4L2MV`
6. **Deployment Target**: watchOS 8.0

### 2. 替換自動產生的檔案
1. 刪除 Xcode 自動產生的 Swift 檔案
2. 將 `ios/ClawfreeWatch/` 內所有 `.swift` 檔案拖入 Xcode 的 ClawfreeWatch group
3. 將 `ios/ClawfreeWatch/Assets.xcassets` 拖入替換
4. 將 `ios/ClawfreeWatch/Info.plist` 設為 target 的 Info.plist

### 3. Build Settings
- **WATCHOS_DEPLOYMENT_TARGET**: 8.0
- **PRODUCT_BUNDLE_IDENTIFIER**: `com.rollbytes.clawfree.watchkitapp`
- **DEVELOPMENT_TEAM**: `3HUWM4L2MV`

### 4. iOS 端 WatchConnectivity（之後實作）
iOS Runner 需要加入 `WCSessionDelegate` 來接收 Watch 傳來的語音檔案，
並將 AI 回覆透過 `sendMessage` 回傳給 Watch。

## 注意事項
- 不使用 `NavigationStack`（需要 watchOS 9+），改用 `VStack`
- 音訊格式：M4A / AAC / 16kHz / mono / 32kbps
- Watch → iPhone 用 `transferFile` 傳送錄音（背景也能運作）
