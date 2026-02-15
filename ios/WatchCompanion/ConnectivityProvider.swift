import WatchConnectivity
import SwiftUI

class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    @Published var activeAgentCount: Int = 0
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    @Published var lastAiReply: String?
    @Published var isReachable: Bool = false
    @Published var isPhoneActive: Bool = false

    var healthColor: Color {
        switch healthLevel {
        case "nominal": return .green
        case "degraded": return .orange
        case "error": return .red
        default: return .gray
        }
    }

    var statusLabel: String {
        if isListening { return "Listening..." }
        if !isReachable { return "iPhone not reachable" }
        switch healthLevel {
        case "nominal": return "System Nominal"
        case "degraded": return "Degraded"
        case "error": return "API Error"
        default: return "Connecting..."
        }
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            print("[Watch] WCSession supported, activating...")
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print("[Watch] WCSession NOT supported on this device")
        }
    }

    /// Send a voice command text to the iPhone app.
    func sendVoiceCommand(_ text: String) {
        let state = WCSession.default.activationState
        print("[Watch→Phone] sendVoiceCommand('\(text)') state=\(state.rawValue) reachable=\(WCSession.default.isReachable)")

        guard state == .activated else {
            print("[Watch→Phone] BLOCKED: WCSession not activated (state=\(state.rawValue))")
            return
        }

        let payload: [String: Any] = [
            "type": "voice_command",
            "text": text,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        if WCSession.default.isReachable {
            print("[Watch→Phone] Sending via sendMessage (reachable)")
            WCSession.default.sendMessage(payload, replyHandler: { reply in
                print("[Watch→Phone] ACK received: \(reply)")
            }, errorHandler: { error in
                print("[Watch→Phone] sendMessage FAILED: \(error.localizedDescription), falling back to transferUserInfo")
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            print("[Watch→Phone] Not reachable, using transferUserInfo")
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// 傳送結構化指令到 iPhone（帶參數，用於 genUI 同步）
    func sendCommand(command: String, params: [String: Any] = [:]) {
        let state = WCSession.default.activationState
        print("[Watch→Phone] sendCommand('\(command)') params=\(params) state=\(state.rawValue)")

        guard state == .activated else {
            print("[Watch→Phone] BLOCKED: WCSession not activated")
            return
        }

        var payload: [String: Any] = [
            "type": "command",
            "command": command,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if !params.isEmpty {
            payload["params"] = params
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: { reply in
                print("[Watch→Phone] Command ACK: \(reply)")
            }, errorHandler: { error in
                print("[Watch→Phone] sendCommand FAILED: \(error.localizedDescription), falling back")
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// 傳送 Watch UI 狀態到 iPhone（即時同步每一步操作）
    func sendUIState(_ state: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        var payload = state
        payload["type"] = "ui_state"
        payload["timestamp"] = Int(Date().timeIntervalSince1970 * 1000)

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: { error in
                print("[Watch→Phone] UI state send failed: \(error.localizedDescription)")
            })
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[Watch] activation complete: state=\(activationState.rawValue) reachable=\(session.isReachable) error=\(error?.localizedDescription ?? "none")")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[Watch] reachability changed: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.activeAgentCount = applicationContext["activeAgentCount"] as? Int ?? 0
            self.healthLevel = applicationContext["healthLevel"] as? String ?? "nominal"
            self.isListening = applicationContext["isListening"] as? Bool ?? false
            self.isPhoneActive = applicationContext["isPhoneActive"] as? Bool ?? false

            // 從 iPhone 接收 Groq API Key
            if let groqKey = applicationContext["groqApiKey"] as? String, !groqKey.isEmpty {
                GroqSTTService.setApiKey(groqKey)
                print("[Watch] Groq API Key received from iPhone")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("[Watch] didReceiveMessage: \(message)")
        DispatchQueue.main.async {
            if let reply = message["aiReply"] as? String {
                print("[Watch] Got AI reply: \(reply.prefix(80))...")
                self.lastAiReply = reply
                WatchTTSService.shared.speak(reply)
            }
        }
    }
}
