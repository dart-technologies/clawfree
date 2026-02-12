import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var recorder = AudioRecorder()
    @State private var showTextInput = false

    var body: some View {
        VStack(spacing: 12) {
            if sessionManager.messages.isEmpty {
                Spacer()
                Text("點擊麥克風或鍵盤開始")
                    .foregroundColor(.gray)
                    .font(.caption)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(sessionManager.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .onChange(of: sessionManager.messages.count) {
                        if let last = sessionManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                // Recording button
                Button(action: toggleRecording) {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(recorder.isRecording ? .red : .orange)
                }
                .buttonStyle(.plain)

                // Text input button (for simulator testing)
                Button(action: { showTextInput = true }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            if !sessionManager.isConnected {
                Text("iPhone 未連線")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Clawfree")
        .sheet(isPresented: $showTextInput) {
            TextInputView(sessionManager: sessionManager)
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            if let audioData = recorder.stopRecording() {
                let userMsg = WatchMessage(
                    id: UUID().uuidString,
                    text: "🎙️ 語音訊息已發送...",
                    isUser: true,
                    timestamp: Date()
                )
                sessionManager.messages.append(userMsg)
                sessionManager.sendVoiceData(audioData)
            }
        } else {
            recorder.startRecording()
        }
    }
}

/// Text input view for simulator testing (no mic available)
struct TextInputView: View {
    @ObservedObject var sessionManager: WatchSessionManager
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("傳送文字指令")
                .font(.headline)

            TextField("輸入指令...", text: $text)
                .textFieldStyle(.plain)

            Button("傳送") {
                guard !text.isEmpty else { return }
                sessionManager.sendTextCommand(text)
                text = ""
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(text.isEmpty)

            Button("取消") { dismiss() }
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: WatchMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .font(.caption2)
                .padding(6)
                .background(message.isUser ? Color.orange.opacity(0.3) : Color.gray.opacity(0.3))
                .cornerRadius(8)
            if !message.isUser { Spacer() }
        }
    }
}
