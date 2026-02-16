# MyChat 三設備 Demo 視頻製作指南

**建立時間：** 2026-02-16 23:45  
**目標：** 錄製並合成 Watch | iPhone | macOS 三設備並排 Demo 視頻

---

## 📋 前置檢查

### 已完成
- ✅ Watch Demo v8: `demo_videos/watch_demo_v8_no_control_20260216_223714.mp4` (45.58s)
- ✅ iPhone 17 Pro 模擬器已啟動
- ✅ macOS 環境準備完成
- ✅ ffmpeg 已安裝 (`/opt/homebrew/bin/ffmpeg`)

### 待完成
- ⏳ iPhone Demo（使用 DEMO_MODE）
- ⏳ macOS Demo（使用 DEMO_MODE）
- ⏳ 三設備並排視頻合成

---

## 🎬 錄製流程

### Step 1: 錄製 iPhone Demo

```bash
cd /Users/roypctw/dev/clawfree
./record_three_device_demo.sh
```

**執行內容：**
- 啟動 iPhone 17 Pro 模擬器
- 運行 Flutter app（DEMO_MODE=true）
- 自動錄製 50 秒（稍長於 Watch demo）
- 輸出：`demo_videos/iphone_demo_YYYYMMDD_HHMMSS.mp4`

**注意事項：**
- 腳本啟動後，請在 iPhone 模擬器中**手動執行 Demo 腳本**（12 步旅遊規劃流程）
- Demo 腳本應與 Watch demo 相同
- 錄製會在 50 秒後自動停止

---

### Step 2: 錄製 macOS Demo

```bash
cd /Users/roypctw/dev/clawfree
./record_macos_demo.sh
```

**執行內容：**
- 啟動 macOS Flutter app（DEMO_MODE=true）
- 提供螢幕錄製指引
- 需要手動使用 Cmd+Shift+5 或 QuickTime 錄製

**錄製步驟：**
1. 執行腳本後，按 Enter 確認準備好
2. 使用 **Cmd+Shift+5** 開啟螢幕錄製工具
3. 選擇「錄製選取視窗」，點選 Clawfree macOS 視窗
4. 按「錄製」按鈕
5. 在 macOS app 中**手動執行 Demo 腳本**（12 步旅遊規劃流程）
6. Demo 完成後，按工具列的「停止」按鈕
7. 將錄製的視頻儲存為：`demo_videos/macos_demo_YYYYMMDD_HHMMSS.mp4`

---

### Step 3: 合成三設備視頻

```bash
cd /Users/roypctw/dev/clawfree
python3 merge_demo_videos.py
```

**執行內容：**
- 自動偵測最新的 iPhone 和 macOS demo
- 使用固定的 Watch demo v8
- 分析三個視頻的尺寸和時長
- 使用 ffmpeg 合成為並排格式（Watch | iPhone | macOS）
- 調整所有視頻到相同高度，保持比例
- 使用最短視頻的時長
- 輸出：`demo_videos/mychat_3device_demo_final.mp4`

**合成邏輯：**
```
[Watch]  +  [iPhone]  +  [macOS]
  縮放       縮放         縮放
    ↓          ↓            ↓
[相同高度] [相同高度]  [相同高度]
    ↓          ↓            ↓
    ╔══════════════════════════╗
    ║  Watch │ iPhone │ macOS ║
    ╚══════════════════════════╝
```

---

## 📊 預期輸出

**最終檔案：**
```
demo_videos/mychat_3device_demo_final.mp4
```

**預期規格：**
- 格式：MP4 (H.264)
- 尺寸：約 3000x800 pixels（依實際設備解析度而定）
- 時長：約 45-50 秒
- 排列：Watch | iPhone | macOS（水平並排）

---

## 🔍 驗證步驟

完成合成後，執行以下驗證：

1. **播放視頻**
   ```bash
   open demo_videos/mychat_3device_demo_final.mp4
   ```

2. **檢查項目**
   - ✅ 三個設備畫面都清晰可見
   - ✅ 時間軸同步（三個設備的操作流程一致）
   - ✅ 無黑邊或變形
   - ✅ 畫質清晰
   - ✅ 時長正確（約 45-50 秒）

3. **檔案資訊**
   ```bash
   ls -lh demo_videos/mychat_3device_demo_final.mp4
   ffprobe -v error -show_entries format=duration \
           -of default=noprint_wrappers=1:nokey=1 \
           demo_videos/mychat_3device_demo_final.mp4
   ```

---

## 📤 傳送到 Telegram

驗證無誤後，傳送到 Topic 9062：

```
message(action=send, 
        filePath='demo_videos/mychat_3device_demo_final.mp4', 
        threadId=9062,
        caption='🎬 MyChat 三設備 Demo - Watch │ iPhone │ macOS')
```

---

## 🚨 問題排查

### iPhone 模擬器錄製失敗
```bash
# 檢查模擬器狀態
xcrun simctl list devices | grep iPhone

# 重啟模擬器
xcrun simctl shutdown all
xcrun simctl boot <IPHONE_ID>
```

### macOS 錄製權限問題
- 確認「系統偏好設定 → 安全性與隱私 → 螢幕錄製」已授權給相關 app
- 使用 QuickTime Player 作為替代方案

### FFmpeg 合成錯誤
```bash
# 檢查 ffmpeg 版本
ffmpeg -version

# 測試單個視頻
ffprobe demo_videos/watch_demo_v8_no_control_20260216_223714.mp4
ffprobe demo_videos/iphone_demo_YYYYMMDD_HHMMSS.mp4
ffprobe demo_videos/macos_demo_YYYYMMDD_HHMMSS.mp4
```

### 時間軸不同步
- 確保三個設備執行的是**完全相同的 Demo 腳本**
- 調整錄製時機（同時開始錄製）
- 使用視頻編輯軟體手動對齊（如 iMovie, Final Cut Pro）

---

## 📝 Demo 腳本範例

**12 步旅遊規劃流程**（應在三個設備上執行相同流程）：

1. 開啟 app
2. 點擊「新對話」
3. 輸入：「幫我規劃東京三天兩夜行程」
4. 等待 AI 回應
5. 查看行程建議
6. 詢問：「第一天的交通方式？」
7. 查看交通建議
8. 詢問：「推薦的住宿地點？」
9. 查看住宿建議
10. 詢問：「需要準備什麼？」
11. 查看準備清單
12. 結束對話

**重要：** 三個設備應盡量**同步執行**相同步驟，以確保合成後的視頻流暢自然。

---

## 🎯 成功標準

- ✅ 三個設備畫面清晰
- ✅ 時間軸同步（±2 秒內）
- ✅ 無技術問題（黑屏、卡頓）
- ✅ Demo 流程完整（12 步驟）
- ✅ 視頻長度適中（45-50 秒）
- ✅ 檔案大小合理（< 50MB）

---

**預估完成時間：** 10-15 分鐘  
**最後更新：** 2026-02-16 23:45
