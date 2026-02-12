import Foundation
import Flutter
import WatchConnectivity

/// Bridges WatchConnectivity ↔ Flutter MethodChannel
class WatchSessionHandler: NSObject, WCSessionDelegate, FlutterStreamHandler {
    static let shared = WatchSessionHandler()

    private var methodChannel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup(with controller: FlutterViewController) {
        // MethodChannel: Flutter → Native (send reply to Watch)
        methodChannel = FlutterMethodChannel(
            name: "com.rollbytes.chatclaw/watch",
            binaryMessenger: controller.binaryMessenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)

        // EventChannel: Native → Flutter (voice data from Watch)
        let eventChannel = FlutterEventChannel(
            name: "com.rollbytes.chatclaw/watch_events",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(self)

        // Activate WCSession
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Flutter → Native

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "sendReply":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'text'", details: nil))
                return
            }
            sendReplyToWatch(text)
            result(nil)

        case "isWatchReachable":
            result(WCSession.default.isReachable)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendReplyToWatch(_ text: String) {
        guard WCSession.default.isReachable else {
            print("[iPhone] Watch not reachable, cannot send reply")
            return
        }
        WCSession.default.sendMessage(
            ["aiReply": text],
            replyHandler: nil,
            errorHandler: { error in
                print("[iPhone] Send to watch error: \(error)")
            }
        )
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - WCSessionDelegate — Receive from Watch

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata,
              metadata["type"] as? String == "voice" else { return }

        let destDir = FileManager.default.temporaryDirectory
        let destURL = destDir.appendingPathComponent("watch_voice_\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: file.fileURL, to: destURL)

            DispatchQueue.main.async {
                self.eventSink?([
                    "type": "voice",
                    "filePath": destURL.path,
                    "timestamp": metadata["timestamp"] ?? Date().timeIntervalSince1970
                ])
            }
            print("[iPhone] Received watch voice file: \(destURL.path)")
        } catch {
            print("[iPhone] Failed to copy watch voice file: \(error)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Notification that voice is incoming
        print("[iPhone] Received watch message: \(message)")
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[iPhone] WCSession activated: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
