import WatchConnectivity
import Foundation

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var messages: [WatchMessage] = []
    @Published var isConnected = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - 傳送文字指令到 iPhone（模擬器測試用）

    func sendTextCommand(_ text: String) {
        let userMsg = WatchMessage(
            id: UUID().uuidString,
            text: text,
            isUser: true,
            timestamp: Date()
        )
        DispatchQueue.main.async {
            self.messages.append(userMsg)
        }

        guard WCSession.default.activationState == .activated else {
            print("[Watch] WCSession not activated, cannot send text command")
            return
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["type": "textCommand", "text": text, "timestamp": Date().timeIntervalSince1970],
                replyHandler: { reply in
                    if let replyText = reply["aiReply"] as? String {
                        DispatchQueue.main.async {
                            self.messages.append(WatchMessage(
                                id: UUID().uuidString,
                                text: replyText,
                                isUser: false,
                                timestamp: Date()
                            ))
                        }
                    }
                },
                errorHandler: { error in
                    print("[Watch] sendTextCommand error: \(error)")
                    DispatchQueue.main.async {
                        self.messages.append(WatchMessage(
                            id: UUID().uuidString,
                            text: "❌ 傳送失敗",
                            isUser: false,
                            timestamp: Date()
                        ))
                    }
                }
            )
        } else {
            // Fallback: use userInfo transfer (queued, delivered later)
            WCSession.default.transferUserInfo([
                "type": "textCommand",
                "text": text,
                "timestamp": Date().timeIntervalSince1970
            ])
            print("[Watch] iPhone not reachable, queued via transferUserInfo")
        }
    }

    // MARK: - 傳送語音資料到 iPhone

    func sendVoiceData(_ audioData: Data) {
        guard WCSession.default.activationState == .activated else {
            print("[Watch] WCSession not activated")
            return
        }

        // Transfer file (works even when iPhone app is not in foreground)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(Int(Date().timeIntervalSince1970)).m4a")
        do {
            try audioData.write(to: tempURL)
            WCSession.default.transferFile(tempURL, metadata: [
                "type": "voice",
                "timestamp": Date().timeIntervalSince1970
            ])
            print("[Watch] Voice file queued for transfer: \(audioData.count) bytes")
        } catch {
            print("[Watch] Failed to write temp audio: \(error)")
        }

        // Also try interactive message if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["type": "voiceNotification", "timestamp": Date().timeIntervalSince1970],
                replyHandler: nil,
                errorHandler: { error in
                    print("[Watch] sendMessage error: \(error)")
                }
            )
        }
    }

    // MARK: - 接收 iPhone 回傳的 AI 回覆

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let text = message["aiReply"] as? String {
            DispatchQueue.main.async {
                self.messages.append(WatchMessage(
                    id: UUID().uuidString,
                    text: text,
                    isUser: false,
                    timestamp: Date()
                ))
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let text = message["aiReply"] as? String {
            DispatchQueue.main.async {
                self.messages.append(WatchMessage(
                    id: UUID().uuidString,
                    text: text,
                    isUser: false,
                    timestamp: Date()
                ))
            }
        }
        replyHandler(["status": "received"])
    }

    // MARK: - WCSessionDelegate required

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        if let error = error {
            print("[Watch] Activation error: \(error)")
        }
    }
}
