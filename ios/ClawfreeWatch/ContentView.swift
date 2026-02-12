import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var recorder = AudioRecorder()

    var body: some View {
        VStack(spacing: 12) {
            if sessionManager.messages.isEmpty {
                Spacer()
                Text("點擊麥克風開始")
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
                    .onChange(of: sessionManager.messages.count) { _ in
                        if let last = sessionManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Recording button
            Button(action: toggleRecording) {
                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(recorder.isRecording ? .red : .orange)
            }
            .buttonStyle(.plain)

            if !sessionManager.isConnected {
                Text("iPhone 未連線")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Clawfree")
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
