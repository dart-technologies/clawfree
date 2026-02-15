import SwiftUI
import Combine

/// Runs the combined Story 1 + Story 2 demo script on Watch.
///
/// Flow:
/// 1. "Plan a 3-day foodie trip to Tokyo" → user voice (male TTS)
/// 2. AI: "Creating your travel agent..." → AI voice (female TTS)
/// 3. "Save Agent" → user voice
/// 4. AI: "Agent saved! Setting up your trip..." → AI voice
/// 5. (No home navigation — seamless transition)
/// 6. "Plan a trip" → user voice
/// 7. AI: "Tokyo pre-selected, 3 days, foodie theme" → AI voice
/// 8. "Generate Itinerary" → user voice
/// 9. AI: "Here's your Tokyo foodie itinerary..." → AI voice
/// 10. "Book Trip" → user voice
/// 11. AI: "Booked! Your trip is confirmed." → AI voice (stay on screen)
class DemoScriptRunner: ObservableObject {
    static let shared = DemoScriptRunner()

    struct ScriptStep {
        let text: String
        let isUser: Bool       // true = user (male), false = AI (female)
        let delayAfter: Double // seconds to wait after this step
        let sendToPhone: Bool  // send via WCSession to iPhone
    }

    /// The combined Story 1 + 2 script (no home navigation between stories).
    let script: [ScriptStep] = [
        // Story 1: Create Agent
        ScriptStep(text: "Plan a 3-day foodie trip to Tokyo", isUser: true, delayAfter: 2.0, sendToPhone: true),
        ScriptStep(text: "Creating your travel agent...", isUser: false, delayAfter: 3.0, sendToPhone: false),
        ScriptStep(text: "Save Agent", isUser: true, delayAfter: 2.0, sendToPhone: true),
        ScriptStep(text: "Agent saved! Setting up your trip...", isUser: false, delayAfter: 2.5, sendToPhone: false),

        // Story 2: Plan Trip (seamless — no home navigation)
        ScriptStep(text: "Plan a trip", isUser: true, delayAfter: 2.5, sendToPhone: true),
        ScriptStep(text: "Tokyo pre-selected, 3 days, foodie theme ready!", isUser: false, delayAfter: 2.0, sendToPhone: false),
        ScriptStep(text: "Generate Itinerary", isUser: true, delayAfter: 3.0, sendToPhone: true),
        ScriptStep(text: "Day 1: Tsukiji → Ginza. Day 2: Shibuya → Harajuku. Day 3: Asakusa → Akihabara.", isUser: false, delayAfter: 3.0, sendToPhone: false),
        ScriptStep(text: "Book Trip", isUser: true, delayAfter: 2.0, sendToPhone: true),
        ScriptStep(text: "Booked! ANA flights + Hoshinoya Tokyo confirmed. 🎉", isUser: false, delayAfter: 0, sendToPhone: false),
    ]

    @Published var currentStepIndex: Int = -1
    @Published var chatMessages: [(text: String, isUser: Bool)] = []
    @Published var isRunning = false
    @Published var isComplete = false

    private let tts = TTSService.shared
    private let earcon = EarconPlayer.shared
    private var timer: Timer?

    /// Start the full demo script.
    func start(connectivity: ConnectivityProvider) {
        guard !isRunning else { return }
        isRunning = true
        isComplete = false
        currentStepIndex = -1
        chatMessages = []

        playNextStep(connectivity: connectivity)
    }

    /// Stop and reset.
    func stop() {
        timer?.invalidate()
        timer = nil
        tts.stop()
        isRunning = false
    }

    private func playNextStep(connectivity: ConnectivityProvider) {
        currentStepIndex += 1

        guard currentStepIndex < script.count else {
            // Demo complete
            isRunning = false
            isComplete = true
            earcon.play(.success)
            return
        }

        let step = script[currentStepIndex]

        // Add to chat history
        withAnimation(.easeInOut(duration: 0.3)) {
            chatMessages.append((text: step.text, isUser: step.isUser))
        }

        // Play earcon
        if step.isUser {
            earcon.play(.thinking)
        } else if currentStepIndex == script.count - 1 {
            earcon.play(.success)
        } else {
            earcon.play(.surfaceArrival)
        }

        // TTS
        tts.speak(step.text, voice: step.isUser ? .male : .female)

        // Send to iPhone via WCSession
        if step.sendToPhone {
            connectivity.sendVoiceCommand(step.text)
        }

        // Schedule next step
        if step.delayAfter > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: step.delayAfter, repeats: false) { [weak self] _ in
                self?.playNextStep(connectivity: connectivity)
            }
        }
    }
}
