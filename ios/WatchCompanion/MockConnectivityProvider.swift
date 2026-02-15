import SwiftUI
import Foundation

/// Mock connectivity for simulator — uses HTTP POST to localhost:8888
/// instead of WCSession (which doesn't work in simulator).
class MockConnectivityProvider: ObservableObject {
    @Published var activeAgentCount: Int = 2
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    @Published var lastAiReply: String?
    @Published var isReachable: Bool = true
    @Published var isPhoneActive: Bool = true

    /// Mock server URL — localhost works between Watch and iPhone simulators
    private let serverURL = "http://localhost:8888"

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
        return "Mock Mode — Connected"
    }

    init() {
        print("[MockConnectivity] Initialized (HTTP mode)")
        // Check server health
        checkServerHealth()
    }

    // MARK: - Send Commands

    /// Send a voice command text to iPhone via mock server
    func sendVoiceCommand(_ text: String) {
        let payload: [String: Any] = [
            "type": "voice_command",
            "text": text,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        postToServer(payload)
    }

    /// Send a structured command (plan_a_trip, create_agent) with params
    func sendCommand(command: String, params: [String: Any] = [:]) {
        var payload: [String: Any] = [
            "type": "command",
            "command": command,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if !params.isEmpty {
            payload["params"] = params
        }
        postToServer(payload)
    }

    /// Send Watch UI state for genUI sync
    func sendUIState(_ state: [String: Any]) {
        var payload = state
        payload["type"] = "ui_state"
        payload["timestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        postToServer(payload)
    }

    // MARK: - HTTP

    private func postToServer(_ payload: [String: Any]) {
        guard let url = URL(string: "\(serverURL)/command") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("[MockConnectivity] JSON serialize error: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[MockConnectivity] POST failed: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isReachable = false }
                return
            }
            let httpResponse = response as? HTTPURLResponse
            print("[MockConnectivity] POST /command → \(httpResponse?.statusCode ?? 0)")
            DispatchQueue.main.async { self.isReachable = true }
        }.resume()
    }

    private func checkServerHealth() {
        guard let url = URL(string: "\(serverURL)/health") else { return }
        URLSession.shared.dataTask(with: url) { _, response, error in
            let ok = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                self.isReachable = ok
                print("[MockConnectivity] Server health: \(ok ? "✅" : "❌")")
            }
        }.resume()
    }
}
