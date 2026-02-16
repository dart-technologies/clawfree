import AVFoundation

/// TTS service — speaks AI responses on Watch via AVSpeechSynthesizer.
class WatchTTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = WatchTTSService()

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()

    /// Voice gender for TTS
    enum VoiceGender {
        case male
        case female
    }

    override init() {
        super.init()
        synthesizer.delegate = self

        // Configure audio session for playback on Watch
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [])
        try? session.setActive(true)
    }

    /// Speak the given text with specified voice gender.
    /// - Parameters:
    ///   - text: Text to speak
    ///   - voice: Voice gender (male: lower pitch, female: higher pitch)
    func speak(_ text: String, voice: VoiceGender = .female) {
        // Stop any current speech first
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Use default en-US voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        // Differentiate by pitch and rate
        switch voice {
        case .male:
            // Lower pitch and slightly slower for male voice
            utterance.pitchMultiplier = 0.85
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        case .female:
            // Higher pitch and slightly faster for female voice
            utterance.pitchMultiplier = 1.15
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        }

        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Stop speaking immediately.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
