# Watch ↔ iPhone Simulator Pairing & Testing Guide

## Prerequisites
- Xcode 16+ installed
- `feat/watch-connectivity` branch checked out

## 1. Pair iPhone + Watch Simulators

1. Open **Xcode → Window → Devices and Simulators**
2. Click the **Simulators** tab
3. Click **+** at bottom-left to create a new simulator (or use existing)
4. For Watch: choose **Apple Watch Series 9** or later, watchOS 11+
5. For iPhone: choose **iPhone 15** or later, iOS 17+
6. In the simulator list, find your Watch simulator → click it → under **Paired iPhone**, select the iPhone simulator

**Alternative (CLI):**
```bash
# List available Watch simulators
xcrun simctl list devices watch

# List available iPhone simulators  
xcrun simctl list devices iphone

# Pair them (use UDIDs from above)
xcrun simctl pair <WATCH_UDID> <IPHONE_UDID>
```

## 2. Build & Run

### iPhone (Flutter app)
```bash
# Option A: Flutter CLI (launches on iPhone simulator)
flutter run -d <IPHONE_SIMULATOR_UDID>

# Option B: Xcode
# Open ios/Runner.xcworkspace → Select Runner scheme → iPhone simulator → Run
```

### Watch app
```bash
# Option A: xcodebuild
cd ios
xcodebuild -target ClawfreeWatch -sdk watchsimulator -configuration Debug

# Option B: Xcode
# Open ios/Runner.xcworkspace → Select ClawfreeWatch scheme → Watch simulator → Run
```

**Recommended:** Use Xcode to run both simultaneously:
1. Open `ios/Runner.xcworkspace`
2. First, run **Runner** on iPhone simulator
3. Then switch scheme to **ClawfreeWatch**, select paired Watch simulator → Run

## 3. Test Data Transfer

1. On the Watch simulator, tap the **keyboard icon** (⌨️) 
2. Type a text command (e.g., "Hello from Watch")
3. Tap **傳送** (Send)
4. The iPhone app should receive the message via `WatchBridge.onWatchEvent`
5. The Watch should display the reply

### Verify connectivity in Console.app
1. Open **Console.app**
2. Filter by `[Watch]` or `[iPhone]` to see WatchConnectivity logs

## 4. Troubleshooting

| Issue | Solution |
|-------|----------|
| "iPhone 未連線" on Watch | Ensure simulators are paired and both apps are running |
| No messages received | Check Console.app for WCSession activation errors |
| Watch app won't build | Ensure SDKROOT=watchos in ClawfreeWatch build settings |
| `flutter build ios` fails with Watch errors | This is expected — Watch target must be built separately via `xcodebuild` |

## Architecture

```
┌─────────────────┐     WCSession      ┌──────────────────┐
│  ClawfreeWatch   │ ←──────────────→  │    Runner (iOS)    │
│  (watchOS app)   │   sendMessage /   │                    │
│                  │   transferFile     │ WatchSessionHandler│
│ WatchSession     │                   │  ↕ MethodChannel   │
│   Manager        │                   │ Flutter WatchBridge│
└─────────────────┘                    └──────────────────┘
```

- **Watch → iPhone:** `sendMessage` (interactive) or `transferUserInfo` (queued)
- **iPhone → Watch:** `sendMessage` with `aiReply` key
- **Flutter integration:** `EventChannel` for Watch→Flutter, `MethodChannel` for Flutter→Watch
