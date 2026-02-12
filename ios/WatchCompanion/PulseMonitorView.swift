import SwiftUI

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @State private var pulseAmount: CGFloat = 1.0

    private var pulseDuration: Double {
        switch connectivity.healthLevel {
        case "nominal": return 1.2
        case "degraded": return 0.6
        case "error": return 0.3
        default: return 1.5
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Agent Count Header
            Text("\(connectivity.activeAgentCount) Agent\(connectivity.activeAgentCount == 1 ? "" : "s") Active")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer()

            // Heartbeat Ring
            ZStack {
                // Outer Pulse
                Circle()
                    .stroke(connectivity.healthColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulseAmount)
                    .opacity(2.0 - pulseAmount)

                // Main Ring
                Circle()
                    .stroke(connectivity.healthColor, lineWidth: 6)
                    .frame(width: 80, height: 80)

                // Mic Icon
                VStack(spacing: 2) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(connectivity.healthColor)

                    Text(connectivity.isListening ? "Listening" : "Speak")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(connectivity.healthColor)
                }
            }
            .frame(width: 100, height: 100)
            .onChange(of: connectivity.healthLevel) { _ in
                pulseAmount = 1.0
                withAnimation(Animation.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    pulseAmount = 1.2
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    pulseAmount = 1.2
                }
            }

            Spacer()

            // Status Label
            Text(connectivity.statusLabel)
                .font(.system(size: 11))
                .foregroundColor(connectivity.healthColor)
        }
        .padding()
    }
}

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
