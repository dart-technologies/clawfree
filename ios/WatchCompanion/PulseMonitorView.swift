import SwiftUI

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared
    @State private var pulseAmount: CGFloat = 1.0
    @State private var showVoiceInput = false

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

                    // Phone Active Banner
                    if connectivity.isPhoneActive {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone")
                                .font(.system(size: 9))
                            Text("Phone Active")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }

                    // Agent Count
                    Text("\(connectivity.activeAgentCount) Agent\(connectivity.activeAgentCount == 1 ? "" : "s") Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Heartbeat Ring — PRIMARY VOICE TRIGGER
                    ZStack {
                        Circle()
                            .stroke(connectivity.healthColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAmount)
                            .opacity(2.0 - pulseAmount)

                        Circle()
                            .stroke(connectivity.healthColor, lineWidth: 5)
                            .frame(width: 60, height: 60)

                        Image(systemName: tts.isSpeaking ? "speaker.wave.2.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(connectivity.healthColor)
                    }
                    .frame(width: 80, height: 80)
                    .contentShape(Circle())
                    .onTapGesture {
                        if tts.isSpeaking {
                            tts.stop()
                        } else {
                            showVoiceInput = true
                        }
                    }
                    .onChange(of: connectivity.healthLevel) { _ in
                        restartPulse()
                    }
                    .onAppear {
                        restartPulse()
                    }

                    Text(tts.isSpeaking ? "Speaking..." : "Tap to speak")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(connectivity.healthColor)

                    // AI Reply bubble (also shown on main screen)
                    if let reply = connectivity.lastAiReply {
                        Text(reply)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.cyan.opacity(0.2))
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .onTapGesture {
                                WatchTTSService.shared.speak(reply)
                            }
                    }

                    // Status + keyboard fallback
                    HStack {
                        Text(connectivity.statusLabel)
                            .font(.system(size: 10))
                            .foregroundColor(connectivity.healthColor)

                        Spacer()

                        // Tiny keyboard button
                        Button(action: { showVoiceInput = true }) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 4)
            }
            .fullScreenCover(isPresented: $showVoiceInput) {
                VoiceInputScreen(connectivity: connectivity)
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

// MARK: - Voice Input Screen (stays open for continuous conversation)

struct VoiceInputScreen: View {
    @ObservedObject var connectivity: ConnectivityProvider
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var sentConfirmation = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    // Mic indicator — tap to re-trigger dictation
                    ZStack {
                        Circle()
                            .fill(isInputFocused ? Color.cyan.opacity(0.25) : Color.cyan.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.cyan)
                    }
                    .onTapGesture {
                        isInputFocused = true
                    }

                    if sentConfirmation {
                        Label("Sent", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text("Tap mic or speak")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    // Text input — auto-focuses to trigger dictation
                    TextField("Speak...", text: $inputText)
                        .focused($isInputFocused)
                        .font(.system(size: 14))

                    // Send button
                    Button(action: sendMessage) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                            Text("Send")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    // AI reply in conversation
                    if let reply = connectivity.lastAiReply {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.cyan.opacity(0.7))
                            Text(reply)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cyan.opacity(0.15))
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            WatchTTSService.shared.speak(reply)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 12))
                }
            }
            .onAppear {
                // Auto-trigger dictation when voice screen opens
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isInputFocused = true
                }
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        connectivity.sendVoiceCommand(trimmed)
        inputText = ""

        // Show sent confirmation
        withAnimation { sentConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { sentConfirmation = false }
        }

        // Auto re-trigger dictation for next message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isInputFocused = true
        }
    }
}

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
