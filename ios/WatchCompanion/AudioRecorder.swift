import AVFoundation
import Foundation

/// 真實錄音器 — 使用 AVAudioRecorder 錄製音檔供 Groq Whisper STT 使用。
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    /// 錄音檔案的暫存路徑
    var currentRecordingURL: URL? { recordingURL }

    /// 開始錄音（m4a 格式，16kHz，單聲道）
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        let fileName = "watch_recording_\(Int(Date().timeIntervalSince1970)).m4a"
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            errorMessage = nil
            print("[AudioRecorder] Started recording to \(recordingURL!.path)")
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
            print("[AudioRecorder] Error: \(error)")
        }
    }

    /// 停止錄音，回傳錄音檔 URL
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        print("[AudioRecorder] Stopped recording")
        return recordingURL
    }

    /// 清理錄音暫存檔
    func cleanup() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
}
