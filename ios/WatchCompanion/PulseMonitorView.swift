import SwiftUI

// MARK: - Main Watch View — One‑tap voice‑first UX

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared

    /// 當前顯示的互動流程
    @State private var activeFlow: InteractiveFlow = .none

    enum InteractiveFlow {
        case none           // 主畫面（語音）
        case agentConfig    // 建 Agent 流程
        case tripPlanner    // 規劃旅行流程
    }

    /// Current UI phase
    @State private var phase: VoicePhase = .idle
    /// Pulsing animation scale for the mic ring
    @State private var pulseScale: CGFloat = 1.0
    /// Recording ring animation
    @State private var recordingPulse: CGFloat = 1.0
    /// Dictation result (set by TextField sheet)
    @State private var dictatedText: String = ""
    /// Show the dictation sheet
    @State private var showDictation = false

    enum VoicePhase {
        case idle       // Big mic button
        case recording  // Listening… (dictation active)
        case sending    // Sending…
        case reply      // AI answered
    }

    // MARK: - Brand colours
    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)   // #FF6B35
    private let teal          = Color(red: 0.0, green: 0.75, blue: 0.65)   // #00BFA5
    private let darkBg        = Color(red: 0.1, green: 0.1, blue: 0.1)     // #1A1A1A

    private var accentColor: Color {
        switch phase {
        case .idle:      return teal
        case .recording: return .red
        case .sending:   return lobsterOrange
        case .reply:     return teal
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            // 互動流程覆蓋主畫面
            switch activeFlow {
            case .agentConfig:
                AgentConfigView(
                    connectivity: connectivity,
                    onComplete: { command in
                        connectivity.sendVoiceCommand(command)
                        withAnimation { activeFlow = .none; phase = .sending }
                    },
                    onCancel: { withAnimation { activeFlow = .none } }
                )
            case .tripPlanner:
                TripPlannerView(
                    connectivity: connectivity,
                    onComplete: { command in
                        connectivity.sendVoiceCommand(command)
                        withAnimation { activeFlow = .none; phase = .sending }
                    },
                    onCancel: { withAnimation { activeFlow = .none } }
                )
            case .none:
                mainVoiceView
            }
        }
        .sheet(isPresented: $showDictation) {
            DictationSheet(text: $dictatedText, onDone: handleDictationDone)
        }
        .onAppear { startIdlePulse() }
        .onChange(of: connectivity.lastAiReply) { newReply in
            if newReply != nil && phase == .sending {
                withAnimation(.easeInOut(duration: 0.3)) { phase = .reply }
                if let r = newReply {
                    WatchTTSService.shared.speak(r)
                }
            }
        }
    }

    // MARK: - 主語音畫面
    private var mainVoiceView: some View {
        VStack(spacing: 8) {
                // Branding bar
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised.slash.fill")
                        .font(.system(size: 10))
                        .foregroundColor(lobsterOrange)
                    Text("Clawfree")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(lobsterOrange)

                    Spacer()

                    if connectivity.isPhoneActive {
                        Image(systemName: "iphone")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 12)

                Spacer()

                // ── Central mic button (60%+ of screen) ──
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(accentColor.opacity(0.25), lineWidth: 3)
                        .scaleEffect(pulseScale)
                        .opacity(Double(2.0 - pulseScale))

                    // Recording pulse ring (only when recording)
                    if phase == .recording {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 4)
                            .scaleEffect(recordingPulse)
                            .opacity(Double(2.0 - recordingPulse))
                    }

                    // Main circle
                    Circle()
                        .fill(accentColor.opacity(0.15))

                    Circle()
                        .stroke(accentColor, lineWidth: 4)

                    // Icon / state
                    micIcon
                }
                .frame(width: 110, height: 110)
                .contentShape(Circle())
                .onTapGesture { handleTap() }

                // Status label
                statusText
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)

                Spacer()

                // AI reply bubble (compact)
                if phase == .reply, let reply = connectivity.lastAiReply {
                    replyBubble(reply)
                }

                // Connection status
                HStack(spacing: 4) {
                    Circle()
                        .fill(connectivity.isReachable ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(connectivity.isReachable ? "Connected" : "Offline")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 2)

                // 快捷操作按鈕（idle 或 reply 時顯示）
                if phase == .idle || phase == .reply {
                    HStack(spacing: 6) {
                        Button(action: { withAnimation { activeFlow = .agentConfig } }) {
                            HStack(spacing: 2) {
                                Image(systemName: "cpu")
                                    .font(.system(size: 8))
                                Text("建 Agent")
                                    .font(.system(size: 9))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.bordered)
                        .tint(lobsterOrange)

                        Button(action: { withAnimation { activeFlow = .tripPlanner } }) {
                            HStack(spacing: 2) {
                                Image(systemName: "airplane")
                                    .font(.system(size: 8))
                                Text("規劃旅行")
                                    .font(.system(size: 9))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.bordered)
                        .tint(teal)
                    }
                    .padding(.bottom, 2)
                }
            }
        }
    

    // MARK: - Sub‑views

    @ViewBuilder
    private var micIcon: some View {
        switch phase {
        case .idle:
            Image(systemName: "mic.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(accentColor)
        case .recording:
            Image(systemName: "waveform")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.red)
        case .sending:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(lobsterOrange)
        case .reply:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(teal)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch phase {
        case .idle:
            Text("Tap to speak")
        case .recording:
            Text("Listening…")
        case .sending:
            Text("Sending…")
        case .reply:
            Text("Tap mic to continue")
        }
    }

    @ViewBuilder
    private func replyBubble(_ reply: String) -> some View {
        ScrollView {
            Text(reply)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(teal.opacity(0.15))
        )
        .padding(.horizontal, 8)
        .onTapGesture {
            WatchTTSService.shared.speak(reply)
        }
    }

    // MARK: - Actions

    private func handleTap() {
        switch phase {
        case .idle, .reply:
            // Stop any TTS, start dictation
            tts.stop()
            withAnimation(.easeInOut(duration: 0.2)) { phase = .recording }
            startRecordingPulse()
            // Open dictation sheet
            dictatedText = ""
            showDictation = true
        case .recording:
            // Tapping again while recording → cancel
            showDictation = false
            withAnimation { phase = .idle }
        case .sending:
            break // ignore taps while sending
        }
    }

    private func handleDictationDone() {
        showDictation = false
        let trimmed = dictatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            withAnimation { phase = .idle }
            return
        }
        let lower = trimmed.lowercased()

        // 語音觸發互動流程
        if lower.contains("create") && lower.contains("agent") {
            withAnimation { phase = .idle; activeFlow = .agentConfig }
            return
        }
        if lower.contains("plan") && (lower.contains("trip") || lower.contains("travel")) {
            withAnimation { phase = .idle; activeFlow = .tripPlanner }
            return
        }

        // 一般語音指令 → 直接發送到 iPhone
        withAnimation(.easeInOut(duration: 0.2)) { phase = .sending }
        connectivity.sendVoiceCommand(trimmed)
    }

    // MARK: - Animations

    private func startIdlePulse() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.25
        }
    }

    private func startRecordingPulse() {
        recordingPulse = 1.0
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            recordingPulse = 1.4
        }
    }
}

// MARK: - Dictation Sheet (minimal — auto‑focus TextField triggers watchOS dictation)

struct DictationSheet: View {
    @Binding var text: String
    var onDone: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Recording indicator
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "mic.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red)
            }

            Text("Speak now")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)

            // Hidden TextField — triggers system dictation
            TextField("", text: $text)
                .focused($focused)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .onSubmit { onDone() }

            // Send button (for manual submit after dictation)
            Button(action: onDone) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 16))
                    Text("Send")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 1.0, green: 0.42, blue: 0.21))
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .onAppear {
            // Auto-trigger dictation keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focused = true
            }
        }
    }
}

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
