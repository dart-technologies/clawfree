import SwiftUI

// MARK: - V1 Watch Demo — 3 States: Idle / Conversation / Complete

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared
    @StateObject private var demoRunner = DemoScriptRunner.shared

    /// V1 only has 3 states
    enum DemoState {
        case idle          // Logo + "Ready to Assist" + Mic
        case conversation  // Chat bubbles + control bar
        case complete      // Logo + ✅ + Trip details + Mic
    }

    @State private var demoState: DemoState = .idle

    // MARK: - Config
    private let isAutoDemoMode = true

    // MARK: - Brand colours (matching HTML gradient #667eea → #764ba2)
    private let brandPurple = Color(red: 0.4, green: 0.49, blue: 0.92)    // #667eea
    private let brandViolet = Color(red: 0.46, green: 0.29, blue: 0.64)   // #764ba2
    private let darkBg = Color(red: 0.1, green: 0.1, blue: 0.18)          // #1a1a2e
    private let userBubbleColor = Color(red: 0.39, green: 0.39, blue: 1.0).opacity(0.35)
    private let aiBubbleColor = Color(red: 0.59, green: 0.59, blue: 0.59).opacity(0.25)
    private let successColor = Color(red: 0.29, green: 0.87, blue: 0.5)   // #4ade80
    private let highlightColor = Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.3)

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.18),
                         Color(red: 0.09, green: 0.13, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch demoState {
            case .idle:
                idleView
            case .conversation:
                conversationView
            case .complete:
                completeView
            }
        }
        .onAppear {
            if isAutoDemoMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    startDemo()
                }
            }
        }
        .onChange(of: demoRunner.isRunning) { running in
            if running && demoState == .idle {
                withAnimation(.easeInOut(duration: 0.5)) {
                    demoState = .conversation
                }
            }
        }
        .onChange(of: demoRunner.isComplete) { complete in
            if complete {
                withAnimation(.easeInOut(duration: 0.5)) {
                    demoState = .complete
                }
            }
        }
    }

    // MARK: - Idle State (Step 1)

    private var idleView: some View {
        VStack(spacing: 10) {
            Spacer()

            // Clawfree Logo (circular with white background)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.white.opacity(0.2), radius: 8)

                Image("ClawfreeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            }

            // Brand name
            Text("Clawfree")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            // Subtitle
            Text("Ready to Assist")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)

            Spacer()

            // Mic button
            Button(action: startDemo) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [brandPurple, brandViolet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: brandPurple.opacity(0.4), radius: 8, y: 2)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            // Hint
            Text("Tap Mic to Start")
                .font(.system(size: 13))
                .foregroundColor(brandPurple)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Conversation State (Steps 2-11)

    private var conversationView: some View {
        ZStack {
            // Messages area
            VStack(spacing: 0) {
                // Chat messages with auto-scroll
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(demoRunner.chatMessages) { msg in
                                messageBubble(for: msg)
                                    .id(msg.id)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 20) // Minimal padding (no control bar)
                    }
                    .onChange(of: demoRunner.chatMessages.count) { _ in
                        if let lastMsg = demoRunner.chatMessages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMsg.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(for msg: DemoScriptRunner.ChatMessage) -> some View {
        if msg.isThinking {
            // Thinking dots
            HStack {
                thinkingDotsView
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(aiBubbleColor)
                    )
                Spacer()
            }
        } else if msg.isUser {
            // User message — right aligned, blue
            HStack {
                Spacer()
                Text(msg.text)
                    .font(.system(size: 13))
                    .lineSpacing(2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(userBubbleColor)
                    )
                    .frame(maxWidth: 200, alignment: .trailing)
            }
        } else if msg.isSuccess {
            // Success message — green
            HStack {
                Text(msg.text)
                    .font(.system(size: 13))
                    .lineSpacing(2)
                    .foregroundColor(successColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(successColor.opacity(0.15))
                    )
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
            }
        } else if msg.isHighlight {
            // Highlight message — accent
            HStack {
                Text(msg.text)
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(2)
                    .foregroundColor(Color(red: 0.63, green: 0.77, blue: 1.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(highlightColor)
                    )
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
            }
        } else {
            // AI message — left aligned, gray
            HStack {
                Text(msg.text)
                    .font(.system(size: 13))
                    .lineSpacing(2)
                    .foregroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(aiBubbleColor)
                    )
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
            }
        }
    }

    // MARK: - Thinking Dots Animation

    private var thinkingDotsView: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                ThinkingDot(delay: Double(index) * 0.2)
            }
        }
    }

    // MARK: - Simple Listening Indicator (waveform only)

    private var controlBar: some View {
        VStack(spacing: 0) {
            // Minimal waveform animation
            WaveformView()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.8)
        )
    }

    // MARK: - Complete State (Step 12)

    private var completeView: some View {
        VStack(spacing: 6) {
            Spacer()

            // Logo (smaller)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.white.opacity(0.2), radius: 8)

                Image("ClawfreeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }

            // Trip Booked! (removed ✅ check mark)
            Text("Trip Booked!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            // Trip details (closer to top)
            Text("Tokyo 3-Day Foodie")
                .font(.system(size: 13))
                .foregroundColor(Color.gray)

            Text("ANA + Hoshinoya Tokyo")
                .font(.system(size: 12))
                .foregroundColor(brandPurple)

            Spacer()

            // Mic button to restart (larger)
            Button(action: restartDemo) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [brandPurple, brandViolet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: brandPurple.opacity(0.4), radius: 8, y: 2)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Actions

    private func startDemo() {
        demoRunner.reset()
        withAnimation(.easeInOut(duration: 0.5)) {
            demoState = .conversation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            demoRunner.start(connectivity: connectivity)
        }
    }

    private func backToIdle() {
        demoRunner.stop()
        withAnimation(.easeInOut(duration: 0.3)) {
            demoState = .idle
        }
    }

    private func stopDemo() {
        demoRunner.stop()
        demoRunner.reset()
        withAnimation(.easeInOut(duration: 0.3)) {
            demoState = .idle
        }
    }

    private func restartDemo() {
        demoRunner.reset()
        withAnimation(.easeInOut(duration: 0.3)) {
            demoState = .idle
        }
    }
}

// MARK: - Thinking Dot Animation

struct ThinkingDot: View {
    let delay: Double
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(Color(red: 0.4, green: 0.49, blue: 0.92))
            .frame(width: 8, height: 8)
            .offset(y: animating ? -10 : 0)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animating
            )
            .onAppear { animating = true }
    }
}

// MARK: - Preview

struct PulseMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PulseMonitorView()
    }
}
