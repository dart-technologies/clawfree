import Foundation

/// Groq Whisper STT 服務 — 將錄音檔送到 Groq API 轉錄（支援中英文）。
class GroqSTTService {
    static let shared = GroqSTTService()

    // API Key 從環境變數或 iPhone 端傳入；開發時可設定在 Xcode scheme 的環境變數
    private var apiKey: String {
        // 優先使用動態設定的 key
        if let key = GroqSTTService._dynamicApiKey, !key.isEmpty { return key }
        // 其次嘗試環境變數
        if let key = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !key.isEmpty { return key }
        // Fallback: 空字串（會導致 API 呼叫失敗，提示設定 key）
        return ""
    }

    /// 從 iPhone 端動態設定 API Key
    private static var _dynamicApiKey: String?
    static func setApiKey(_ key: String) {
        _dynamicApiKey = key
    }
    private let endpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
    private let model = "whisper-large-v3-turbo"

    /// 轉錄音檔，回傳文字結果
    func transcribe(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(STTError.noApiKey))
            return
        }
        guard let audioData = try? Data(contentsOf: fileURL) else {
            completion(.failure(STTError.fileNotFound))
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()

        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)

        // language field — 不指定，讓 Whisper 自動偵測中英文
        // response_format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("[GroqSTT] Sending \(audioData.count) bytes to Groq Whisper...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[GroqSTT] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(STTError.emptyResponse))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("[GroqSTT] Transcription: \(trimmed)")
                    completion(.success(trimmed))
                } else {
                    let raw = String(data: data, encoding: .utf8) ?? "?"
                    print("[GroqSTT] Unexpected response: \(raw)")
                    completion(.failure(STTError.parseError(raw)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    enum STTError: LocalizedError {
        case noApiKey
        case fileNotFound
        case emptyResponse
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .noApiKey: return "Groq API Key not set. Sync from iPhone first."
            case .fileNotFound: return "Audio file not found"
            case .emptyResponse: return "Empty response from Groq"
            case .parseError(let msg): return "Parse error: \(msg)"
            }
        }
    }
}
