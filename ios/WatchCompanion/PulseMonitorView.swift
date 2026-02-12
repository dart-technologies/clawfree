import SwiftUI

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
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
            VStack(spacing: 6) {
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
                        .frame(width: 70, height: 70)

                    // Mic Icon
                    VStack(spacing: 2) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(connectivity.healthColor)

                        Text("Tap to speak")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(connectivity.healthColor)
                    }
                }
                .frame(width: 90, height: 90)
                .onTapGesture {
                    showDictation = true
                }
                .onChange(of: connectivity.healthLevel) { _ in
                    restartPulse()
                }
                .onAppear {
                    restartPulse()
                }

                // Last AI reply
                if let reply = connectivity.lastAiReply {
                    Text(reply)
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                        .lineLimit(3)
                        .padding(.horizontal, 4)
                }

                // Status Label
                Text(connectivity.statusLabel)
                    .font(.system(size: 10))
                    .foregroundColor(connectivity.healthColor)
            }
            .padding(.vertical, 4)
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

/// A simple dictation input view using watchOS's built-in dictation on TextField.
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
