import SwiftUI

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared
    @State private var pulseAmount: CGFloat = 1.0
    @State private var inputText: String = ""

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
                VStack(spacing: 6) {
                    // Branding
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.slash.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text("Clawfree")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyan)
                    }

                    // Agent Count
                    Text("\(connectivity.activeAgentCount) Agent\(connectivity.activeAgentCount == 1 ? "" : "s") Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Heartbeat Ring + Mic Button
                    ZStack {
                        Circle()
                            .stroke(connectivity.healthColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAmount)
                            .opacity(2.0 - pulseAmount)

                        Circle()
                            .stroke(connectivity.healthColor, lineWidth: 5)
                            .frame(width: 55, height: 55)

                        VStack(spacing: 2) {
                            Image(systemName: tts.isSpeaking ? "speaker.wave.2.fill" : "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(connectivity.healthColor)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .onTapGesture {
                        if tts.isSpeaking {
                            tts.stop()
                        }
                    }
                    .onChange(of: connectivity.healthLevel) { _ in
                        restartPulse()
                    }
                    .onAppear {
                        restartPulse()
                    }

                    // Inline text input — stays visible, no sheet dismissal
                    HStack(spacing: 4) {
                        TextField("Say something...", text: $inputText)
                            .textContentType(.none)
                            .font(.system(size: 13))

                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .cyan)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)

                    // AI Reply bubble
                    if let reply = connectivity.lastAiReply {
                        VStack(spacing: 4) {
                            Text(reply)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.cyan.opacity(0.2))
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 10) {
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
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        connectivity.sendVoiceCommand(trimmed)
        inputText = ""
    }

    private func restartPulse() {
        pulseAmount = 1.0
        withAnimation(Animation.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
            pulseAmount = 1.2
        }
    }
}

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
