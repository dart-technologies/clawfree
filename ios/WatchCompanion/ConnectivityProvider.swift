import WatchConnectivity
import SwiftUI

/// Connectivity provider: sends Watch messages to local sync server via HTTP POST.
/// Falls back to HTTP POST when WCSession is unavailable (simulator).
class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    @Published var activeAgentCount: Int = 0
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    @Published var lastAiReply: String?
    @Published var isReachable: Bool = false
    @Published var isPhoneActive: Bool = false

    /// Demo sync server URL (localhost for simulator)
    private let syncServerURL = "http://localhost:8080/message"

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
        // In simulator, mark as reachable (via HTTP fallback)
        DispatchQueue.main.async {
            self.isReachable = true
        }
    }

    /// Send voice command to sync server (HTTP POST).
    /// Server broadcasts to all connected iPhone / macOS clients.
    func sendVoiceCommand(_ text: String) {
        print("[Watch→Server] sendVoiceCommand('\(text)')")
        sendToSyncServer(text: text, isUser: true)
    }

    /// Send AI reply to sync server
    func sendAIReply(_ text: String) {
        print("[Watch→Server] sendAIReply('\(text.prefix(60))...')")
        sendToSyncServer(text: text, isUser: false)
    }

    /// Send message to local sync server via HTTP POST
    private func sendToSyncServer(text: String, isUser: Bool) {
        guard let url = URL(string: syncServerURL) else {
            print("[Watch→Server] Invalid URL: \(syncServerURL)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0

        let payload: [String: Any] = [
            "text": text,
            "isUser": isUser,
            "source": "watch",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("[Watch→Server] JSON serialization failed: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Watch→Server] Send failed: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[Watch→Server] Response: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    /// Send Watch UI state to sync server
    func sendUIState(_ state: [String: Any]) {
        // UI state is sent via WCSession only (not sync server)
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
