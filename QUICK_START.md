# 🚀 MyChat 三設備 Demo - 快速開始

## ✅ 準備完成

- ✅ Watch Demo v8 (45.58s)
- ✅ iPhone 錄製腳本
- ✅ macOS 錄製腳本
- ✅ 視頻合成腳本
- ✅ 完整操作指南

---

## 📋 執行清單（依序執行）

### 1️⃣ 錄製 iPhone Demo（5 分鐘）

```bash
cd /Users/roypctw/dev/clawfree
./record_three_device_demo.sh
```

**等待腳本啟動後，在 iPhone 模擬器中手動執行 Demo 腳本（12 步旅遊規劃流程）**

---

### 2️⃣ 錄製 macOS Demo（5 分鐘）

```bash
cd /Users/roypctw/dev/clawfree
./record_macos_demo.sh
```

**步驟：**
1. 腳本啟動 macOS app
2. 按 **Cmd+Shift+5** 開啟螢幕錄製
3. 選擇「錄製選取視窗」→ 點選 Clawfree 視窗
4. 按「錄製」
5. 手動執行 Demo 腳本（與 iPhone 相同流程）
6. 完成後按「停止」
7. 將視頻儲存為 `demo_videos/macos_demo_YYYYMMDD_HHMMSS.mp4`

---

### 3️⃣ 合成三設備視頻（2 分鐘）

```bash
cd /Users/roypctw/dev/clawfree
python3 merge_demo_videos.py
```

**自動處理：**
- 偵測最新的 iPhone 和 macOS demo
- 合成為 Watch | iPhone | macOS 並排格式
- 輸出 `demo_videos/mychat_3device_demo_final.mp4`

---

### 4️⃣ 驗證與傳送

**驗證：**
```bash
open demo_videos/mychat_3device_demo_final.mp4
```

**傳送到 Telegram Topic 9062：**
```
message(action=send, 
        filePath='demo_videos/mychat_3device_demo_final.mp4', 
        threadId=9062,
        caption='🎬 MyChat 三設備 Demo - Watch │ iPhone │ macOS')
```

---

## 📝 Demo 腳本（三設備同步執行）

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

---

## 🚨 常見問題

**Q: iPhone 模擬器錄製失敗？**  
A: 檢查模擬器狀態 `xcrun simctl list devices | grep iPhone`

**Q: macOS 錄製沒有權限？**  
A: 系統偏好設定 → 安全性與隱私 → 螢幕錄製 → 授權

**Q: 合成視頻時間軸不對齊？**  
A: 確保三個設備執行相同的 Demo 腳本，並盡量同步操作

---

## 📚 完整文件

詳細說明請參考：`DEMO_RECORDING_GUIDE.md`

---

**預估總時間：** 12-15 分鐘  
**最後更新：** 2026-02-16 23:48
