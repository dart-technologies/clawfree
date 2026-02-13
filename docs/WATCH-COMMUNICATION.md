# Watch Communication Architecture

## Overview

ClawFree supports bidirectional communication between Apple Watch and all client devices (iPhone, iPad, macOS). Since Apple's WatchConnectivity (WCSession) only works between a paired iPhone and Watch, we use a **Gateway Relay** to extend Watch communication to iPad and macOS.

## Architecture Diagram

```
                            ┌─────────────────┐
                            │   Apple Watch    │
                            │  (watchOS app)   │
                            │                  │
                            │  Voice dictation │
                            │  → recognized    │
                            │    text          │
                            └────────┬─────────┘
                                     │
                              WCSession (native)
                         (only works with iPhone)
                                     │
                            ┌────────▼─────────┐
                            │     iPhone       │
                            │  (Flutter app)   │
                            │                  │
                            │ Receives Watch   │
                            │ events via       │
                            │ WCSession +      │
                            │ broadcasts to    │
                            │ Gateway Relay    │
                            └────────┬─────────┘
                                     │
                              POST /watch/relay
                                     │
                            ┌────────▼─────────┐
                            │  Gateway Server  │
                            │  (Node.js)       │
                            │                  │
                            │  /watch/relay    │
                            │  SSE endpoint    │
                            └───┬─────────┬────┘
                                │         │
                          SSE stream   SSE stream
                                │         │
                   ┌────────────▼┐   ┌────▼────────────┐
                   │    iPad     │   │     macOS        │
                   │ (Flutter)   │   │   (Flutter)      │
                   │             │   │                  │
                   │ Relay mode  │   │  Relay mode      │
                   └─────────────┘   └─────────────────┘
```

## Communication Modes

### 1. iPhone — Direct (WCSession)

iPhone is the only device that can communicate directly with Apple Watch via Apple's WatchConnectivity framework.

**Watch → iPhone flow:**
1. User speaks on Watch → watchOS native dictation converts speech to text
2. Watch sends text via `WCSession.sendMessage()` or `transferFile()`
3. `AppDelegate.swift` receives the message in `WCSessionDelegate` callbacks
4. Event is forwarded to Flutter via `FlutterEventChannel` (`art.dart.clawfree/watch_events`)
5. `WatchBridge.onVoiceReceived` stream emits a `WatchVoiceEvent`
6. iPhone also calls `WatchBridge.broadcastToRelay()` to POST the event to the gateway

**iPhone → Watch flow:**
1. Flutter calls `WatchBridge.sendReplyToWatch(text)`
2. Invokes native `MethodChannel` (`art.dart.clawfree/watch`) with method `sendReply`
3. `AppDelegate.swift` sends via `WCSession.default.sendMessage()`
4. Watch receives and displays the AI reply

### 2. iPad & macOS — Gateway Relay (SSE)

iPad and macOS cannot use WCSession. They communicate with Watch indirectly through the Gateway Relay.

**Watch → iPad/macOS flow:**
1. Watch sends voice command to iPhone (via WCSession)
2. iPhone receives it and POSTs to `GET /watch/relay` subscribers via `POST /watch/relay`
3. Gateway broadcasts the event as SSE to all connected clients
4. iPad/macOS receive the event through their SSE subscription
5. `WatchBridge._relayController` emits the `WatchVoiceEvent`

**iPad/macOS → Watch flow:**
1. Flutter calls `WatchBridge.sendReplyToWatch(text)`
2. In relay mode, this POSTs to `POST /watch/relay` with `source: "ipad"`
3. Gateway broadcasts to all SSE subscribers
4. iPhone receives the relay event, detects `source: "ipad"` + `type: "ai_reply"`
5. iPhone forwards to Watch via WCSession `sendMessage()`

## Key Files

| File | Role |
|------|------|
| `lib/src/core/watch_bridge.dart` | Flutter-side bridge — dual mode (WCSession / relay) |
| `ios/Runner/AppDelegate.swift` | Native iOS — WCSession delegate + platform channels |
| `ios/WatchCompanion/` | watchOS app — voice dictation + WCSession |
| `infra/gateway/server.js` | Gateway — `/watch/relay` SSE endpoint |

## Platform Channels

| Channel | Type | Direction | Purpose |
|---------|------|-----------|---------|
| `art.dart.clawfree/watch` | MethodChannel | Flutter → Native | `syncWatch`, `sendReply`, `isWatchReachable` |
| `art.dart.clawfree/watch_events` | EventChannel | Native → Flutter | Watch voice events stream |

## Gateway Relay API

### `GET /watch/relay`

Subscribe to Watch events via Server-Sent Events (SSE).

**Response:** SSE stream. Each event is a JSON object:

```json
// Connection handshake
{"type": "connected"}

// Voice command from Watch (relayed by iPhone)
{"type": "voice_command", "text": "check my schedule", "timestamp": 1707840000000, "source": "iphone"}

// AI reply from iPad/macOS
{"type": "ai_reply", "text": "Here's your schedule...", "timestamp": 1707840001000, "source": "ipad"}
```

### `POST /watch/relay`

Broadcast an event to all SSE subscribers.

**Request body:** JSON object (same format as SSE events above)

**Response:**
```json
{"ok": true, "subscribers": 2}
```

## Device Detection Logic

```dart
// In WatchBridge.configure():
if (Platform.isIOS) {
  // Try WCSession — works on iPhone, fails on iPad
  try {
    await methodChannel.invokeMethod('isWatchReachable');
    // Success → iPhone mode (direct WCSession)
  } on MissingPluginException {
    // Fail → iPad mode (gateway relay)
  }
} else if (Platform.isMacOS) {
  // macOS always uses gateway relay
}
```

## Prerequisites

1. **iPhone ↔ Watch pairing** (simulator: `xcrun simctl pair <watch_id> <iphone_id>`)
2. **Gateway server running** for iPad/macOS relay: `cd infra/gateway && node server.js`
3. **WatchCompanion app installed** on Watch (embedded via Xcode target dependency)

---

## 繁體中文摘要

### 概述

ClawFree 支援 Apple Watch 與所有裝置（iPhone、iPad、macOS）之間的雙向通訊。Apple 的 WCSession 僅支援 iPhone ↔ Watch，因此 iPad 和 macOS 透過 **Gateway Relay（閘道中繼）** 間接通訊。

### 通訊模式

| 路徑 | 方式 |
|------|------|
| Watch ↔ iPhone | WCSession 直連（原生 WatchConnectivity） |
| Watch ↔ iPad | Gateway SSE Relay（iPad 不支援 WCSession） |
| Watch ↔ macOS | Gateway SSE Relay（macOS 不支援 WCSession） |

### 流程

**Watch → iPhone（直連）：**
使用者在 Watch 說話 → watchOS 聽寫辨識為文字 → WCSession 傳至 iPhone → Flutter EventChannel 接收 → 同時廣播至 Gateway Relay

**Watch → iPad/macOS（中繼）：**
Watch → iPhone（WCSession）→ iPhone POST 至 Gateway `/watch/relay` → Gateway SSE 廣播 → iPad/macOS 接收

**iPad/macOS → Watch（中繼）：**
iPad/macOS POST 至 Gateway → iPhone 收到 SSE 事件 → iPhone 透過 WCSession 轉發至 Watch

### 前置條件

1. iPhone ↔ Watch 需配對（模擬器：`xcrun simctl pair <watch_id> <iphone_id>`）
2. iPad/macOS relay 需啟動 Gateway：`cd infra/gateway && node server.js`
3. WatchCompanion app 需安裝於 Watch（透過 Xcode target dependency 嵌入）
