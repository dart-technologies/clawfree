import Foundation

struct WatchMessage: Identifiable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date
}
