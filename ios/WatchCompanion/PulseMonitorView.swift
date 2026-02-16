import SwiftUI

// MARK: - V3 Watch View — Floating FAB 語音助理 UX

struct PulseMonitorView: View {
    @StateObject private var connectivity = ConnectivityProvider()
    @StateObject private var tts = WatchTTSService.shared
    @StateObject private var demoRunner = DemoScriptRunner.shared

    /// 當前顯示的互動流程
    @State private var activeFlow: InteractiveFlow = .none

    enum InteractiveFlow {
        case none           // 主畫面（語音）
        case agentConfig    // 建 Agent 流程
        case tripPlanner    // 規劃旅行流程
    }

    /// V3 UI 階段
    @State private var phase: VoicePhase = .idle

    /// Dictation result
    @State private var dictatedText: String = ""
    @State private var showDictation = false

    // MARK: - Demo Mode
    private let isDemoMode = true
    private let isAutoDemoMode = true
    @State private var demoScriptIndex = 0
    @State private var autoDemoCompleted = 0
    private let demoScripts = [
        "Plan a 3-day foodie trip to Tokyo",
        "Save Agent",
        "Plan a trip",
        "Generate Itinerary",
        "Book Trip"
    ]
    @State private var recognizedText = ""
    @State private var isRecognizing = false

    /// V3 脈衝動畫
    @State private var pulseScale: CGFloat = 1.0
    @State private var micPulseScale: CGFloat = 1.0

    enum VoicePhase {
        case idle        // V3-A: Clawfree + 浮動麥克風
        case listening   // V3-B: 麥克風脈衝 + 送出/取消按鈕
        case recognizing // V3-C: 辨識文字 + 聲波 + 停止
        case reply       // V3-D: 對話訊息 + 聲波 + 停止
        case complete    // V3-E: 成功訊息 + 麥克風重新開始
    }

    // MARK: - Brand colours
    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal          = Color(red: 0.0, green: 0.75, blue: 0.65)
    private let darkBg        = Color(red: 0.1, green: 0.1, blue: 0.1)

    // MARK: - 浮動按鈕大小
    private let fabSize: CGFloat = 44

    // MARK: - Body

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            switch activeFlow {
            case .agentConfig:
                AgentConfigView(
                    connectivity: connectivity,
                    onComplete: { command in
                        connectivity.sendVoiceCommand(command)
                        withAnimation { activeFlow = .none; phase = .recognizing }
                    },
                    onCancel: { withAnimation { activeFlow = .none } }
                )
            case .tripPlanner:
                TripPlannerView(
                    connectivity: connectivity,
                    onComplete: { command in
                        connectivity.sendVoiceCommand(command)
                        withAnimation { activeFlow = .none; phase = .recognizing }
                    },
                    onCancel: { withAnimation { activeFlow = .none } }
                )
            case .none:
                mainV3View
            }
        }
        .sheet(isPresented: $showDictation) {
            DictationSheet(text: $dictatedText, onDone: handleDictationDone)
        }
        .onAppear {
            if isAutoDemoMode && isDemoMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    demoRunner.start(connectivity: connectivity)
                }
            }
        }
        .onChange(of: demoRunner.isRunning) { running in
            if running && phase == .idle {
                withAnimation { phase = .reply }
            }
        }
        .onChange(of: demoRunner.isComplete) { complete in
            if complete {
                withAnimation(.easeInOut(duration: 0.5)) { phase = .complete }
            }
        }
        .onChange(of: connectivity.lastAiReply) { newReply in
            if newReply != nil && phase == .recognizing {
                withAnimation(.easeInOut(duration: 0.3)) { phase = .reply }
                if let r = newReply {
                    WatchTTSService.shared.speak(r)
                }
            }
        }
    }

    // MARK: - V3 主畫面

    private var mainV3View: some View {
        ZStack {
            // 主內容區域
            mainContentArea

            // 浮動按鈕層（always on top）
            VStack {
                // 左上角 ✕ 離開按鈕（V3-D 對話模式）
                HStack {
                    if phase == .reply && demoRunner.isRunning {
                        Button(action: stopAndReset) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                        .padding(.top, 4)
                    }
                    Spacer()
                }

                Spacer()

                // 聲波動畫（V3-C, V3-D）— 縮小高度，緊貼按鈕上方
                if phase == .recognizing || (phase == .reply && demoRunner.isRunning) {
                    WaveformView()
                        .frame(height: 15)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 2)
                }

                // 底部浮動按鈕列
                HStack {
                    // 左下角取消按鈕（V3-B Listening 狀態）
                    if phase == .listening {
                        Button(action: cancelListening) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: fabSize, height: fabSize)
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()

                    // 右下角主按鈕
                    mainFAB
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - 主內容區域（依階段切換）

    @ViewBuilder
    private var mainContentArea: some View {
        switch phase {
        case .idle:
            idleView
        case .listening:
            listeningView
        case .recognizing:
            recognizingView
        case .reply:
            conversationView
        case .complete:
            completeView
        }
    }

    // MARK: - V3-A: Idle 狀態
    private var idleView: some View {
        VStack(spacing: 8) {
            Spacer()

            // 品牌 Logo
            HStack(spacing: 4) {
                Image(systemName: "hand.raised.slash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(lobsterOrange)
                Text("Clawfree")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(lobsterOrange)
            }

            Text("Ready to Assist")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            // 提示文字（麥克風按鈕上方）
            Text("Tap Mic to Start")
                .font(.system(size: 11))
                .foregroundColor(teal.opacity(0.8))
                .padding(.bottom, fabSize + 12)
        }
    }

    // MARK: - V3-B: Listening 狀態
    private var listeningView: some View {
        VStack(spacing: 12) {
            Spacer()

            // 麥克風脈衝動畫
            ZStack {
                // 外圈脈衝
                Circle()
                    .stroke(teal.opacity(0.2), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseScale)

                Circle()
                    .stroke(teal.opacity(0.1), lineWidth: 1)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale * 0.9)

                // 中央麥克風
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(teal)
                    .scaleEffect(micPulseScale)
            }
            .onAppear {
                startListeningPulse()
            }

            Text("Listening…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()
            // 為底部按鈕留空間
            Spacer().frame(height: fabSize + 16)
        }
    }

    // MARK: - V3-C: Recognizing 狀態
    private var recognizingView: some View {
        VStack(spacing: 8) {
            Spacer()

            // 辨識文字
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(teal.opacity(0.15))
                    )
                    .padding(.horizontal, 12)
            }

            if isRecognizing {
                Text("Recognizing…")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
            // 為縮小後的聲波 + 按鈕留空間
            Spacer().frame(height: 60)
        }
    }

    // MARK: - V3-D: Conversation 狀態
    private var conversationView: some View {
        VStack(spacing: 0) {
            // 對話滾動區域
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(demoRunner.chatMessages.enumerated()), id: \.offset) { index, msg in
                            HStack {
                                if msg.isUser {
                                    Spacer()
                                    Text(msg.text)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(teal)
                                        )
                                        .frame(maxWidth: 130, alignment: .trailing)
                                } else {
                                    Text(msg.text)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.2))
                                        )
                                        .frame(maxWidth: 130, alignment: .leading)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 8)
                            .id(index)
                        }

                        // Non-demo AI reply
                        if !demoRunner.isRunning && !demoRunner.isComplete,
                           let reply = connectivity.lastAiReply {
                            HStack {
                                Text(reply)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                                    .frame(maxWidth: 130, alignment: .leading)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 60) // 為縮小後的聲波 + 按鈕留空間
                }
                .onChange(of: demoRunner.chatMessages.count) { _ in
                    if let last = demoRunner.chatMessages.indices.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - V3-E: Complete 狀態
    private var completeView: some View {
        VStack(spacing: 12) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("✅ Successfully created a travel agent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                Text("✅ Successfully planned a food trip to Tokyo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.1))
            )
            .padding(.horizontal, 12)

            Spacer()
            // 為按鈕留空間
            Spacer().frame(height: fabSize + 16)
        }
    }

    // MARK: - 浮動主按鈕（FAB）

    @ViewBuilder
    private var mainFAB: some View {
        switch phase {
        case .idle, .complete:
            // 麥克風按鈕（綠色）
            Button(action: handleMicTap) {
                ZStack {
                    Circle()
                        .fill(teal)
                        .frame(width: fabSize, height: fabSize)
                        .shadow(color: teal.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("micButton")
            .transition(.scale.combined(with: .opacity))

        case .listening:
            // 綠色送出按鈕（✓）
            Button(action: submitListening) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: fabSize, height: fabSize)
                        .shadow(color: Color.green.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))

        case .recognizing, .reply:
            // 紅色停止按鈕
            Button(action: stopAndReset) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: fabSize, height: fabSize)
                        .shadow(color: Color.red.opacity(0.4), radius: 6, y: 2)
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func handleMicTap() {
        if phase == .complete {
            // 重新開始循環
            demoRunner.stop()
            demoRunner.isComplete = false
            demoRunner.chatMessages = []
        }

        if isDemoMode {
            withAnimation(.easeInOut(duration: 0.3)) { phase = .listening }
            // Demo: 1.5 秒後自動進入 recognizing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                playDemoRecognition()
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { phase = .listening }
            dictatedText = ""
            showDictation = true
        }
    }

    private func submitListening() {
        // 送出（Demo 模式下自動進入 recognizing）
        if isDemoMode {
            playDemoRecognition()
        } else {
            handleDictationDone()
        }
    }

    private func cancelListening() {
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .idle
            recognizedText = ""
            isRecognizing = false
        }
        if demoRunner.isRunning { demoRunner.stop() }
    }

    private func stopAndReset() {
        demoRunner.stop()
        demoRunner.isComplete = false
        demoRunner.chatMessages = []
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .idle
            recognizedText = ""
            isRecognizing = false
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

        if lower.contains("create") && lower.contains("agent") {
            withAnimation { phase = .idle; activeFlow = .agentConfig }
            return
        }
        if lower.contains("plan") && (lower.contains("trip") || lower.contains("travel")) {
            withAnimation { phase = .idle; activeFlow = .tripPlanner }
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) { phase = .recognizing }
        recognizedText = trimmed
        connectivity.sendVoiceCommand(trimmed)
    }

    // MARK: - Demo Animation

    private func playDemoRecognition() {
        guard demoScriptIndex < demoScripts.count else {
            demoScriptIndex = 0
            playDemoRecognition()
            return
        }

        let script = demoScripts[demoScriptIndex]

        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .recognizing
            isRecognizing = true
            recognizedText = ""
        }

        // Typewriter effect
        let characters = Array(script)
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < characters.count {
                recognizedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                isRecognizing = false
                // 送出後切到對話模式
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    connectivity.sendVoiceCommand(script)
                    demoScriptIndex += 1
                    // 啟動 DemoScriptRunner 對話
                    if !demoRunner.isRunning {
                        demoRunner.start(connectivity: connectivity)
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        phase = .reply
                        recognizedText = ""
                    }
                }
            }
        }
    }

    // MARK: - Animations

    private func startListeningPulse() {
        pulseScale = 1.0
        micPulseScale = 1.0
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            micPulseScale = 1.1
        }
    }
}

// MARK: - Dictation Sheet

struct DictationSheet: View {
    @Binding var text: String
    var onDone: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
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

            TextField("", text: $text)
                .focused($focused)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .onSubmit { onDone() }

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
