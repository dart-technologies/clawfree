import AVFoundation

/// 語音合成服務 — 在 Watch 上用 AVSpeechSynthesizer 念出 AI 回應。
class WatchTTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = WatchTTSService()

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self

        // Configure audio session for playback on Watch
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [])
        try? session.setActive(true)
    }

    /// Speak the given text. Auto-detects language (defaults to zh-TW, falls back to en-US).
    func speak(_ text: String) {
        // Stop any current speech first
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Auto-detect: if mostly CJK characters, use zh-TW; otherwise en-US
        let cjkCount = text.unicodeScalars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.count
        let ratio = text.isEmpty ? 0.0 : Double(cjkCount) / Double(text.count)
        utterance.voice = AVSpeechSynthesisVoice(language: ratio > 0.1 ? "zh-TW" : "en-US")

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
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
