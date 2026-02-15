# Watch Demo 需求文件

> **更新日期：** 2026-02-16  
> **狀態：** 最終確認版本  
> **目標：** 比賽演示 MVP

---

## 🎯 Demo 目標

展示 Clawfree 的 Apple Watch + iPhone + macOS 三設備無縫協作：
- Watch 語音輸入 → 自動同步到 iPhone 和 macOS
- 從創建 Agent 到完成訂單的完整流程
- 無中斷、流暢的用戶體驗

---

## 📋 Demo 流程（Story 1 + 2 合併）

```
開始
↓
⌚ "Plan a 3-day foodie trip to Tokyo"
↓
🔮 VoiceOrb thinking
↓
📝 Agent form 出現（Travel Concierge, Opus 4.6）
↓
⌚ "Save Agent" → 成功 ✓
↓
❌ 不返回 Home！
↓
🎨 直接進入 Travel Setup genUI
↓
⌚ "Plan a trip" (或自動觸發)
↓
🎨 Tokyo pre-selected, 3-day, foodie
↓
⌚ "Generate Itinerary"
↓
📋 行程顯示（hero 圖、ANA、Hoshinoya）
↓
⌚ "Book Trip" → 成功 → "Booked!" TTS
↓
❌ 不返回 Home！停留在這裡
↓
結束（影片後製解說）
```

---

## ⚙️ 技術規格

### 裝置配置

| 裝置 | 功能 | 狀態 |
|------|------|------|
| ⌚ Apple Watch | 語音輸入 + 對話顯示 | ✅ 必須 |
| 📱 iPhone | WebSocket Server + genUI | ✅ 必須 |
| 💻 macOS | WebSocket Client + genUI | ✅ 必須 |
| 📱 iPad | - | ❌ 不要 |

### TTS 語音

| 角色 | 聲音 | Voice ID |
|------|------|----------|
| 🎙️ 用戶說話 | 男聲 | `AVSpeechSynthesisVoiceIdentifierAlex` |
| 🎤 AI 回應 | 女聲 | `AVSpeechSynthesisVoiceIdentifierSamantha` |

### Watch 功能

1. **顯示對話文字**：對話氣泡（用戶 vs AI）
2. **語音輸入自動同步**：Watch → iPhone + macOS
3. **持續監聽模式**：無需重複按鈕

---

## 🎬 關鍵特性

### 無縫流程
- ❌ **不返回 Home**：Story 1 完成後直接進入 Story 2
- ❌ **不返回 Home**：Story 2 完成後停留在結果頁面

### 自動演示模式
- 代碼配置：`isAutoDemoMode = true` + `isDemoMode = true`
- App 啟動 2 秒後自動開始
- 自動執行完整 Story 1 + 2 流程（約 20 秒）

### 多設備同步
- Watch 語音輸入 → `WatchConnectivity` → iPhone
- iPhone → `WebSocket` → macOS
- 實時顯示對話歷史

---

## 📂 相關文件

- **實作代碼：**
  - `ios/WatchCompanion/PulseMonitorView.swift` - Watch UI
  - `ios/WatchCompanion/DemoScriptRunner.swift` - 自動演示腳本
  - `ios/WatchCompanion/TTSService.swift` - TTS 語音服務
  - `ios/WatchCompanion/ConnectivityProvider.swift` - WatchConnectivity
  - `lib/src/core/watch_bridge.dart` - Flutter 橋接

- **輔助工具：**
  - `run_three_device_demo.sh` - 啟動腳本
  - `launch_demo_apps.scpt` - AppleScript 啟動（實驗性）

---

## 🚀 執行方式

### 方式 A：自動化腳本（推薦）
```bash
cd /Users/roypctw/dev/clawfree
./run_three_device_demo.sh
```

### 方式 B：手動啟動
```bash
# Terminal Tab 1: macOS
cd /Users/roypctw/dev/clawfree
flutter run -d macos

# Terminal Tab 2: iPhone (Watch 會自動啟動)
cd /Users/roypctw/dev/clawfree
flutter run -d <iPhone_ID>
```

### 方式 C：子任務啟動（透過酪梨管家）
```
讓酪梨管家開子任務執行 Demo
```

---

## 🎥 錄製建議

1. **工具：** QuickTime Player
   - 新增螢幕錄製（macOS 畫面）
   - 新增影片錄製（iPhone 模擬器）

2. **畫面配置：**
   - Watch 畫面（包含在 iPhone 模擬器內）
   - iPhone 畫面（中間）
   - macOS 畫面（旁邊）

3. **時間點：**
   - App 啟動後等待 2 秒
   - Demo 自動開始
   - 錄製完整 20 秒流程

---

## ✅ 完成檢查清單

- [ ] 三設備同時啟動
- [ ] Demo 自動開始（2 秒延遲）
- [ ] Watch 語音輸入正確顯示
- [ ] iPhone 接收並顯示訊息
- [ ] macOS 同步顯示對話
- [ ] TTS 語音正確（男聲 + 女聲）
- [ ] Earcon 音效正確播放
- [ ] Story 1 → Story 2 無縫轉換
- [ ] 完成後停留在結果頁面
- [ ] 錄製完整影片

---

## 🐛 已知限制

1. **模擬器限制：**
   - WatchConnectivity 在模擬器之間無法真實通訊
   - 需使用 Mock Server 或實體裝置

2. **自動化啟動：**
   - `flutter run` 需要 TTY（互動式終端）
   - 無法完全背景執行
   - 建議使用子任務或手動啟動

3. **錄製挑戰：**
   - 需要同時錄製三個裝置畫面
   - 建議使用 QuickTime 分別錄製後合成

---

## 📝 備註

- **分支：** `feature/watch-mike-final-demo`
- **基於：** origin/main `7c9777a`
- **Mike 最新版：** `5ab098b`（包含新的 travel UI 組件）
- **建議：** Demo 錄製完成後再合併 Mike 的最新更新

---

**最後更新：** 2026-02-16 03:17 GMT+8  
**文件維護：** 酪梨管家
