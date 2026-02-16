import WatchConnectivity
import SwiftUI

/// 連線提供者：透過 HTTP POST 將 Watch 訊息發送到本地同步伺服器
/// 模擬器環境下 WCSession 無法使用，改用 HTTP POST 繞過限制
class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    @Published var activeAgentCount: Int = 0
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    @Published var lastAiReply: String?
    @Published var isReachable: Bool = false
    @Published var isPhoneActive: Bool = false

    /// Demo 同步伺服器的 URL（模擬器用 localhost）
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
        // 模擬器環境下，標記為可達（透過 HTTP）
        DispatchQueue.main.async {
            self.isReachable = true
        }
    }

    /// 發送語音指令到同步伺服器（HTTP POST）
    /// 伺服器會廣播給所有連線的 iPhone / macOS 客戶端
    func sendVoiceCommand(_ text: String) {
        print("[Watch→Server] sendVoiceCommand('\(text)')")
        sendToSyncServer(text: text, isUser: true)
    }

    /// 發送 AI 回覆到同步伺服器
    func sendAIReply(_ text: String) {
        print("[Watch→Server] sendAIReply('\(text.prefix(60))...')")
        sendToSyncServer(text: text, isUser: false)
    }

    /// 透過 HTTP POST 將訊息發送到本地同步伺服器
    private func sendToSyncServer(text: String, isUser: Bool) {
        guard let url = URL(string: syncServerURL) else {
            print("[Watch→Server] ❌ 無效的 URL: \(syncServerURL)")
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
            print("[Watch→Server] ❌ JSON 序列化失敗: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Watch→Server] ❌ 發送失敗: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[Watch→Server] ✅ 回應: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    /// 傳送 Watch UI 狀態到同步伺服器
    func sendUIState(_ state: [String: Any]) {
        // UI 狀態目前不透過同步伺服器傳送，保留原有邏輯
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
