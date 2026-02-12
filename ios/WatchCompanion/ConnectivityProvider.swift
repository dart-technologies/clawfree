import WatchConnectivity
import SwiftUI

class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    @Published var activeAgentCount: Int = 0
    @Published var healthLevel: String = "nominal"
    @Published var isListening: Bool = false
    
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
    
    @Published var lastAiReply: String?

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation
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
            }
        }
    }
}
