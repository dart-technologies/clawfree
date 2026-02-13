import SwiftUI

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared
    @State private var pulseAmount: CGFloat = 1.0
    @State private var showDictation = false
    @State private var dictatedText: String = ""

    private var pulseDuration: Double {
        switch connectivity.healthLevel {
        case "nominal": return 1.2
        case "degraded": return 0.6
        case "error": return 0.3
        default: return 1.5
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    // Agent Count Header
                    Text("\(connectivity.activeAgentCount) Agent\(connectivity.activeAgentCount == 1 ? "" : "s") Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Heartbeat Ring + Mic Button
                    ZStack {
                        // Outer Pulse
                        Circle()
                            .stroke(connectivity.healthColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAmount)
                            .opacity(2.0 - pulseAmount)

                        // Main Ring
                        Circle()
                            .stroke(connectivity.healthColor, lineWidth: 5)
                            .frame(width: 60, height: 60)

                        // Mic / Speaker Icon
                        VStack(spacing: 2) {
                            Image(systemName: tts.isSpeaking ? "speaker.wave.2.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(connectivity.healthColor)

                            Text(tts.isSpeaking ? "Speaking..." : "Tap to speak")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(connectivity.healthColor)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .onTapGesture {
                        if tts.isSpeaking {
                            tts.stop()
                        } else {
                            showDictation = true
                        }
                    }
                    .onChange(of: connectivity.healthLevel) { _ in
                        restartPulse()
                    }
                    .onAppear {
                        restartPulse()
                    }

                    // AI Reply bubble
                    if let reply = connectivity.lastAiReply {
                        VStack(spacing: 6) {
                            Text(reply)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cyan.opacity(0.2))
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Action buttons
                            HStack(spacing: 12) {
                                // Reply button — continue dictation conversation
                                Button(action: {
                                    showDictation = true
                                }) {
                                    Label("Reply", systemImage: "mic.fill")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .tint(.cyan)

                                // Replay TTS
                                Button(action: {
                                    WatchTTSService.shared.speak(reply)
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Status Label
                    Text(connectivity.statusLabel)
                        .font(.system(size: 10))
                        .foregroundColor(connectivity.healthColor)
                }
                .padding(.vertical, 4)
            }
            .sheet(isPresented: $showDictation) {
                DictationInputView(
                    text: $dictatedText,
                    onSubmit: { text in
                        showDictation = false
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            connectivity.sendVoiceCommand(text)
                        }
                    }
                )
            }
        }
    }

    private func restartPulse() {
        pulseAmount = 1.0
        withAnimation(Animation.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
            pulseAmount = 1.2
        }
    }
}

/// 語音輸入 — 使用 watchOS 內建 dictation（TextField 上的麥克風按鈕）。
struct DictationInputView: View {
    @Binding var text: String
    var onSubmit: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Speak or type")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            // watchOS TextField automatically shows dictation mic button
            TextField("Say something...", text: $text)
                .textContentType(.none)

            Button("Send") {
                onSubmit(text)
                text = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
