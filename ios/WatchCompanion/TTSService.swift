import AVFoundation

/// Enhanced TTS with male (user) and female (AI) voices for demo.
class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    enum Voice {
        case male    // User voice (Alex)
        case female  // AI voice (Samantha)
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak text with the specified voice.
    func speak(_ text: String, voice: Voice = .female) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95

        switch voice {
        case .male:
            // Alex — deep male voice
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Alex")
                ?? AVSpeechSynthesisVoice(language: "en-US")
            utterance.pitchMultiplier = 0.9
        case .female:
            // Samantha — natural female voice
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.samantha")
                ?? AVSpeechSynthesisVoice(language: "en-US")
            utterance.pitchMultiplier = 1.1
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
