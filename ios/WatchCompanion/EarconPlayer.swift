import AVFoundation
#if os(watchOS)
import WatchKit
#endif

/// Plays short earcon sound effects on Watch.
class EarconPlayer {
    static let shared = EarconPlayer()

    private var player: AVAudioPlayer?

    enum Earcon: String {
        case thinking = "thinking"
        case success = "success"
        case surfaceArrival = "surface_arrival"
    }

    /// Play an earcon by name. Falls back to system haptic if file missing.
    func play(_ earcon: Earcon) {
        let url = Bundle.main.url(forResource: earcon.rawValue, withExtension: "mp3")
            ?? Bundle.main.url(forResource: earcon.rawValue, withExtension: "wav")
        guard let url else {
            playHapticFallback(earcon)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            playHapticFallback(earcon)
        }
    }

    private func playHapticFallback(_ earcon: Earcon) {
        #if os(watchOS)
        switch earcon {
        case .thinking:
            WKInterfaceDevice.current().play(.start)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .surfaceArrival:
            WKInterfaceDevice.current().play(.notification)
        }
        #endif
    }
}
