import Foundation
import SwiftUI

/// Voice input handler for watchOS.
///
/// On watchOS, Speech framework is not available. Instead we use SwiftUI's
/// built-in dictation support via `.searchable` or text field with dictation.
/// This class manages the state for a simple text-input-based flow that
/// uses watchOS dictation (the system mic button on TextField).
class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    /// Called when the user submits dictated/typed text.
    func submit(_ text: String) {
        transcript = text
        isRecording = false
    }

    /// Simulates starting a "recording" session (shows dictation UI).
    func startRecording() {
        isRecording = true
        transcript = ""
        errorMessage = nil
    }

    func stopRecording() {
        isRecording = false
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // No explicit authorization needed for watchOS dictation
        completion(true)
    }
}
