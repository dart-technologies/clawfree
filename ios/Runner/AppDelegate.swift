import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Watch Connectivity Setup
    if WCSession.isSupported() {
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // Flutter platform channels
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let messenger = controller.binaryMessenger

    // MethodChannel — Flutter -> Native (syncWatch, sendReply, isWatchReachable)
    let watchChannel = FlutterMethodChannel(name: "art.dart.clawfree/watch",
                                            binaryMessenger: messenger)
    watchChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "syncWatch":
          if let args = call.arguments as? [String: Any],
             WCSession.default.activationState == .activated,
             WCSession.default.isPaired {
              try? WCSession.default.updateApplicationContext(args)
          }
          result(nil)

      case "sendReply":
          if let args = call.arguments as? [String: Any],
             let text = args["text"] as? String,
             WCSession.default.activationState == .activated,
             WCSession.default.isReachable {
              WCSession.default.sendMessage(["aiReply": text], replyHandler: nil, errorHandler: { error in
                  print("[Watch] sendReply error: \(error.localizedDescription)")
              })
          }
          result(nil)

      case "pingWatch":
          if WCSession.default.activationState == .activated,
             WCSession.default.isPaired,
             WCSession.default.isReachable {
              WCSession.default.sendMessage(["type": "ping"], replyHandler: { _ in
                  result(true)
              }, errorHandler: { _ in
                  result(false)
              })
          } else {
              result(false)
          }

      case "isWatchReachable":
          let reachable = WCSession.default.activationState == .activated
                       && WCSession.default.isPaired
                       && WCSession.default.isReachable
          result(reachable)

      default:
          result(FlutterMethodNotImplemented)
      }
    })

    // EventChannel — Native -> Flutter (voice file events from Watch)
    let eventChannel = FlutterEventChannel(name: "art.dart.clawfree/watch_events",
                                           binaryMessenger: messenger)
    eventChannel.setStreamHandler(WatchEventStreamHandler.shared)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
      if let error = error {
          print("[Watch] activation error: \(error.localizedDescription)")
      } else {
          print("[Watch] activated, state=\(activationState.rawValue), paired=\(session.isPaired), reachable=\(session.isReachable)")
      }
  }
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
      session.activate()
  }

  /// Receives voice audio files transferred from the Watch via `transferFile`.
  func session(_ session: WCSession, didReceive file: WCSessionFile) {
      let tempDir = NSTemporaryDirectory()
      let destURL = URL(fileURLWithPath: tempDir).appendingPathComponent(file.fileURL.lastPathComponent)
      try? FileManager.default.removeItem(at: destURL)
      try? FileManager.default.copyItem(at: file.fileURL, to: destURL)

      let event: [String: Any] = [
          "type": "voice",
          "filePath": destURL.path,
          "timestamp": Int(Date().timeIntervalSince1970 * 1000),
      ]
      WatchEventStreamHandler.shared.send(event)
  }

  /// Receives real-time messages from the Watch (voice commands as text).
  /// This variant handles messages sent WITH a replyHandler.
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
      print("[Watch] didReceiveMessage (replyHandler): \(message)")
      handleWatchVoiceCommand(message)
      replyHandler(["status": "ok"])
  }

  /// Receives real-time messages from the Watch WITHOUT a replyHandler.
  /// Fallback for messages sent without expecting a reply.
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
      print("[Watch] didReceiveMessage (no reply): \(message)")
      handleWatchVoiceCommand(message)
  }

  /// Receives background user info transfers from the Watch.
  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
      print("[Watch] didReceiveUserInfo: \(userInfo)")
      handleWatchVoiceCommand(userInfo)
  }

  /// Common handler for voice commands from Watch (any delivery method).
  private func handleWatchVoiceCommand(_ message: [String: Any]) {
      guard let type = message["type"] as? String else { return }

      let timestamp = message["timestamp"] ?? Int(Date().timeIntervalSince1970 * 1000)

      switch type {
      case "voice_command":
          // 語音指令（舊格式，向後相容）
          if let text = message["text"] as? String {
              WatchEventStreamHandler.shared.send([
                  "type": "voice_command",
                  "text": text,
                  "timestamp": timestamp,
              ])
          }

      case "command":
          // 結構化指令（按鈕觸發）：plan_a_trip, create_agent（含 params）
          if let command = message["command"] as? String {
              var event: [String: Any] = [
                  "type": "command",
                  "command": command,
                  "timestamp": timestamp,
              ]
              if let params = message["params"] as? [String: Any] {
                  event["params"] = params
              }
              WatchEventStreamHandler.shared.send(event)
          }

      case "text":
          // 手錶轉錄文字（Groq Whisper STT 結果）
          if let text = message["text"] as? String {
              WatchEventStreamHandler.shared.send([
                  "type": "text",
                  "text": text,
                  "timestamp": timestamp,
              ])
          }

      case "ui_state":
          // Watch UI 狀態同步 → 直接轉發到 Flutter
          WatchEventStreamHandler.shared.send(message)

      default:
          print("[Watch] Unknown message type: \(type)")
      }
  }
}

// MARK: - EventChannel stream handler with buffering

class WatchEventStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = WatchEventStreamHandler()
    private var eventSink: FlutterEventSink?

    /// Buffer for events received before Flutter connects.
    /// Prevents silent event loss when the app is woken from background.
    private var pendingEvents: [[String: Any]] = []
    private let lock = NSLock()

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        lock.lock()
        self.eventSink = events
        // Flush any buffered events
        let buffered = pendingEvents
        pendingEvents.removeAll()
        lock.unlock()

        for event in buffered {
            print("[Watch] flushing buffered event: \(event)")
            events(event)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        lock.lock()
        self.eventSink = nil
        lock.unlock()
        return nil
    }

    func send(_ event: [String: Any]) {
        DispatchQueue.main.async { [self] in
            lock.lock()
            if let sink = eventSink {
                lock.unlock()
                print("[Watch] sending event to Flutter: \(event)")
                sink(event)
            } else {
                // Buffer the event — Flutter hasn't connected yet
                print("[Watch] buffering event (no sink): \(event)")
                pendingEvents.append(event)
                // Cap buffer to prevent unbounded growth
                if pendingEvents.count > 50 {
                    pendingEvents.removeFirst()
                }
                lock.unlock()
            }
        }
    }
}
