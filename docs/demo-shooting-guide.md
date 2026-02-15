# 🎬 Clawfree Apple Watch Demo — 拍攝指南

> **目標：** 80 秒影片，展示 Watch → iPhone → MacBook 的跨裝置 AI 協作
> **風格：** Apple 產品影片風格（暗色背景、簡潔鏡頭、流暢轉場）

---

## 📋 前置準備

### 裝置清單
| 裝置 | 用途 | 準備 |
|------|------|------|
| Apple Watch | 主角：語音輸入 + 卡片滑動 | 充滿電、調亮度最高 |
| iPhone | 接收訊息 + genUI 顯示 | 開 Mock 畫面（HTML） |
| MacBook | Split screen genUI + Chat | 開 Mock 畫面（HTML） |
| 拍攝手機/相機 | 錄影 | 4K 60fps，腳架 |

### Mock 畫面準備
1. **手錶端：** 用真實 App（TripPlannerView）或螢幕錄影
2. **iPhone：** 開瀏覽器 `demo_videos/mock_screens/iphone-genui-agent.html`
3. **MacBook：** 開瀏覽器 `demo_videos/mock_screens/macbook-split-genui.html`（全螢幕）

### 環境佈置
- **桌面：** 深色/黑色桌面，乾淨無雜物
- **燈光：** 柔光從左上方 45° 打，避免螢幕反光
- **背景：** 純色牆壁或虛化背景

---

## 🎬 場景 1：手錶語音建立 Agent（0:00 - 0:30）

### 鏡頭規劃

| 秒數 | 鏡頭 | 裝置畫面 | 拍攝角度 | 備註 |
|------|------|----------|----------|------|
| 0-3s | **特寫** Watch 螢幕 | 主畫面，麥克風按鈕可見 | 45° 俯拍，手腕微抬 | 開場鏡頭，讓觀眾看到手錶 |
| 3-5s | **手指點擊**麥克風 | 點擊動畫，進入錄音模式 | 同上，稍微拉近 | 自然的手指動作 |
| 5-10s | **特寫** Watch 錄音中 | 波形動畫跳動 | 同上 | 嘴型說「Build a Trip Agent」 |
| 10-15s | **特寫** Watch 文字 | STT 結果：「Build a Trip Agent」 | 同上 | 停頓 1 秒讓觀眾讀 |
| 15-20s | **切到** iPhone | 收到訊息 + AI 回應 | 手持 iPhone 或桌面平放 | 平滑轉場（dissolve） |
| 20-25s | **切到** MacBook | genUI 顯示 Agent 建立選項 | 正面平拍螢幕 | 展示 split screen |
| 25-30s | **MacBook** 特寫 | ✅ Agent 建立完成動畫 | 稍微推進 | 成功畫面停留 |

### 旁白（可後製配音）
> "With just your voice on Apple Watch, create an AI agent instantly. Watch it sync across all your devices in real-time."

### 拍攝要點
- 手錶畫面要**清晰可讀**（調最高亮度）
- 手指動作要**慢且自然**
- 裝置切換用**剪輯轉場**（不需同框）

---

## 🎬 場景 2：手錶卡片選擇 Plan Trip（0:30 - 1:00）

### 鏡頭規劃

| 秒數 | 鏡頭 | 裝置畫面 | 拍攝角度 | 備註 |
|------|------|----------|----------|------|
| 0-5s | **特寫** Watch 卡片 | 手指左右滑動城市卡片 | 45° 俯拍 | 滑 2-3 次，展示流暢度 |
| 5-8s | **特寫** 停在 Tokyo | Tokyo 卡片置中 | 同上 | 稍微停頓 |
| 8-10s | **手指點擊** Tokyo | 點擊確認動畫 | 同上 | 明確的點擊動作 |
| 10-15s | **切到** iPhone | 「Plan a Trip to Tokyo」訊息出現 | 手持或桌面 | 展示即時同步 |
| 15-20s | **iPhone** genUI | genUI 自動展開（選天數/景點） | 同上 | 可以滾動展示 |
| 20-25s | **切到** MacBook | 完整 split screen | 正面平拍 | 左 genUI + 右 Chat |
| 25-30s | **MacBook** 最終規劃 | 完整的旅遊行程表 | 稍微推進 | 展示 Day 1, Day 2... |

### 旁白
> "Swipe through destinations right from your wrist. Tap to select — your trip plan builds itself across every screen."

### 拍攝要點
- 卡片滑動要**流暢**，不要太快
- Tokyo 卡片是主角，停留久一點
- MacBook 最終畫面是**高潮**，停留 3-5 秒

---

## 🎬 場景 3：iPhone 語音規劃（1:00 - 1:20）

### 鏡頭規劃

| 秒數 | 鏡頭 | 裝置畫面 | 拍攝角度 | 備註 |
|------|------|----------|----------|------|
| 0-5s | **手持** iPhone | 點擊麥克風 → 說話 | 45° 手持 | 「Plan a trip to Tokyo」 |
| 5-10s | **iPhone** 螢幕 | STT 文字 + AI 回應 | 近距離螢幕特寫 | 文字逐漸出現 |
| 10-15s | **拉遠** 多裝置 | iPhone + MacBook 同框 | 桌面俯拍 | 展示同步效果 |
| 15-20s | **最終鏡頭** | 所有裝置顯示完成畫面 | 寬角度桌面俯拍 | 結束畫面 + Logo |

### 旁白
> "Or speak directly on your iPhone. Every device stays in perfect sync. That's Clawfree."

### 拍攝要點
- 最後的多裝置同框是**收尾重點**
- 裝置擺放：Watch 左前、iPhone 中間、MacBook 後方
- 最後加 Clawfree Logo + tagline

---

## 🎨 後製指南

### 轉場
| 位置 | 效果 | 時長 |
|------|------|------|
| 場景內裝置切換 | Cross Dissolve | 0.5s |
| 場景之間 | Fade to Black | 0.8s |
| 開場/結尾 | Fade In/Out | 1.0s |

### 字幕
- **位置：** 底部居中，白字黑底半透明
- **字體：** SF Pro Display / Helvetica Neue
- **內容：** 顯示語音指令文字（如 "Build a Trip Agent"）

### 音效/配樂
- **配樂：** 輕快科技感（Apple 風格，推薦 Artlist 或 Epidemic Sound）
- **音效：** 點擊音效（subtle click）、成功音效（chime）
- **語音：** 後製配音或字幕替代

### 片頭/片尾
- **片頭（3s）：** Clawfree Logo + "Your AI, Everywhere"
- **片尾（5s）：** Logo + GitHub URL + "Built with ❤️"

---

## 📐 螢幕錄影設定

### Apple Watch
- 從 iPhone 的 Watch App → 開啟螢幕錄影
- 或用 Xcode 的 Device → Screen Recording

### iPhone / MacBook
- QuickTime Player → New Screen Recording
- 解析度：原生解析度
- FPS：60fps

---

## ✅ 拍攝前 Checklist

- [ ] 所有裝置充滿電
- [ ] Mock HTML 畫面已開啟並測試
- [ ] Watch App 已安裝（TripPlannerView 可運作）
- [ ] 桌面整理乾淨
- [ ] 燈光測試（無反光）
- [ ] 相機/手機腳架就位
- [ ] 測試錄影 10 秒確認畫質
- [ ] 關閉所有通知（勿擾模式）
- [ ] 準備好旁白稿

---

## 📁 檔案結構

```
demo_videos/
├── generate-watch-cards.html    ← 開瀏覽器生成卡片截圖
├── mock_screens/
│   ├── iphone-genui-agent.html  ← iPhone Mock（Agent 建立）
│   └── macbook-split-genui.html ← MacBook Mock（Split genUI + Chat）
├── watch_cards/                 ← 截圖後放這裡
│   ├── Tokyo.png
│   ├── Paris.png
│   ├── NewYork.png
│   └── London.png
└── raw/                         ← 拍攝原始素材
    ├── scene1_watch_voice/
    ├── scene2_watch_cards/
    └── scene3_iphone_voice/
```
