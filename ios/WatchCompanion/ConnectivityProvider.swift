import WatchConnectivity
import SwiftUI

class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    @Published var activeAgentCount: Int = 0
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    @Published var lastAiReply: String?
    @Published var isReachable: Bool = false

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
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Send a voice command text to the iPhone app.
    func sendVoiceCommand(_ text: String) {
        guard WCSession.default.activationState == .activated else { return }

        let payload: [String: Any] = [
            "type": "voice_command",
            "text": text,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: { reply in
                DispatchQueue.main.async {
                    if let ack = reply["status"] as? String, ack == "ok" {
                        // acknowledged
                    }
                }
            }, errorHandler: { error in
                print("sendMessage error: \(error.localizedDescription)")
                // Fall back to transferUserInfo for background delivery
                WCSession.default.transferUserInfo(payload)
            })
        } else {
            // Background delivery
            WCSession.default.transferUserInfo(payload)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.activeAgentCount = applicationContext["activeAgentCount"] as? Int ?? 0
            self.healthLevel = applicationContext["healthLevel"] as? String ?? "nominal"
            self.isListening = applicationContext["isListening"] as? Bool ?? false
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let reply = message["aiReply"] as? String {
                self.lastAiReply = reply
                // Auto-speak AI replies on Watch
                WatchTTSService.shared.speak(reply)
            }
        }
    }
}
