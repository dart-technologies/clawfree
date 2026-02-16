import SwiftUI
import Combine

/// V1 Demo: 12-step story matching the HTML prototype.
///
/// States: idle → conversation (steps 2-11) → complete (step 12)
class DemoScriptRunner: ObservableObject {
    static let shared = DemoScriptRunner()

    struct ScriptStep {
        let text: String
        let isUser: Bool          // true = user (male TTS), false = AI (female TTS)
        let delayAfter: Double    // seconds to wait after this step
        let sendToPhone: Bool     // send via WCSession to iPhone
        let isThinking: Bool      // show thinking dots instead of text
        let isSuccess: Bool       // green success style
        let isHighlight: Bool     // highlight/accent style
    }

    /// The complete 12-step V1 story (matching HTML prototype)
    let script: [ScriptStep] = [
        // Step 2: User speaks
        ScriptStep(text: "Plan a 3-day foodie trip to Tokyo",
                   isUser: true, delayAfter: 5.0, sendToPhone: true,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 3: AI Thinking (wait for genUI to display)
        ScriptStep(text: "",
                   isUser: false, delayAfter: 2.5, sendToPhone: false,
                   isThinking: true, isSuccess: false, isHighlight: false),

        // Step 4: Agent created (longer delay for user to browse genUI)
        ScriptStep(text: "I've created a Travel Concierge Agent with Claude Opus 4.6, all tools and channels enabled.",
                   isUser: false, delayAfter: 8.0, sendToPhone: false,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 5: User confirms (after reviewing genUI)
        ScriptStep(text: "OK, confirm",
                   isUser: true, delayAfter: 1.5, sendToPhone: true,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 6: Agent saved
        ScriptStep(text: "✓ Agent saved successfully!",
                   isUser: false, delayAfter: 2.0, sendToPhone: false,
                   isThinking: false, isSuccess: true, isHighlight: false),

        // Step 7: AI starts planning
        ScriptStep(text: "Perfect! I'll start planning your 3-day foodie trip to Tokyo now.",
                   isUser: false, delayAfter: 6.0, sendToPhone: false,
                   isThinking: false, isSuccess: false, isHighlight: true),

        // Step 8: User requests itinerary
        ScriptStep(text: "Generate Itinerary",
                   isUser: true, delayAfter: 0.5, sendToPhone: true,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 8b: AI thinking for itinerary (短暫顯示，立即進入結果)
        ScriptStep(text: "",
                   isUser: false, delayAfter: 0.5, sendToPhone: false,
                   isThinking: true, isSuccess: false, isHighlight: false),

        // Step 9: Itinerary ready (5秒展示 genUI)
        ScriptStep(text: "Here's your Tokyo foodie adventure:\n\n• Day 1: Tsukiji Market\n• Day 2: Ramen masterclass\n• Day 3: Michelin kaiseki\n\nFlight: ANA ✓\nHotel: Hoshinoya Tokyo",
                   isUser: false, delayAfter: 5.0, sendToPhone: false,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 10: User books trip (after reviewing itinerary)
        ScriptStep(text: "Book Trip",
                   isUser: true, delayAfter: 1.5, sendToPhone: true,
                   isThinking: false, isSuccess: false, isHighlight: false),

        // Step 11: Booking in progress
        ScriptStep(text: "Booking your trip now...",
                   isUser: false, delayAfter: 2.0, sendToPhone: false,
                   isThinking: false, isSuccess: false, isHighlight: false),
    ]

    // MARK: - Chat Message Model

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let isThinking: Bool
        let isSuccess: Bool
        let isHighlight: Bool
    }

    @Published var currentStepIndex: Int = -1
    @Published var chatMessages: [ChatMessage] = []
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

    /// Reset to initial state.
    func reset() {
        stop()
        isComplete = false
        chatMessages = []
        currentStepIndex = -1
    }

    private func playNextStep(connectivity: ConnectivityProvider) {
        currentStepIndex += 1

        guard currentStepIndex < script.count else {
            // All conversation steps done → transition to Complete
            isRunning = false
            isComplete = true
            earcon.play(.success)
            return
        }

        let step = script[currentStepIndex]

        // If this is a thinking step, replace previous thinking dots first
        if !step.isThinking {
            // Remove any existing thinking message
            withAnimation(.easeInOut(duration: 0.3)) {
                chatMessages.removeAll { $0.isThinking }
            }
        }

        // Add to chat history
        let msg = ChatMessage(
            text: step.text,
            isUser: step.isUser,
            isThinking: step.isThinking,
            isSuccess: step.isSuccess,
            isHighlight: step.isHighlight
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            chatMessages.append(msg)
        }

        // Play earcon
        if step.isUser {
            earcon.play(.thinking)
        } else if step.isSuccess {
            earcon.play(.success)
        } else {
            earcon.play(.surfaceArrival)
        }

        // TTS (skip for thinking dots)
        if !step.isThinking {
            tts.speak(step.text, voice: step.isUser ? .male : .female)
        }

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
