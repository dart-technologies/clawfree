import SwiftUI

// MARK: - 建 Agent 互動流程（Watch 端）
// 步驟：選模型 → 選技能 → 確認建立

struct AgentConfigView: View {
    @ObservedObject var connectivity: ConnectivityProvider
    var onComplete: (String) -> Void  // 完成後回傳指令文字
    var onCancel: () -> Void

    // 品牌色
    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal = Color(red: 0.0, green: 0.75, blue: 0.65)
    private let darkBg = Color(red: 0.1, green: 0.1, blue: 0.1)

    // 步驟狀態
    @State private var step = 0  // 0=模型, 1=技能, 2=確認
    @State private var selectedModel = 0
    @State private var skills: [SkillItem] = [
        SkillItem(name: "Flight Search", emoji: "✈️", selected: true),
        SkillItem(name: "Hotel Booking", emoji: "🏨", selected: true),
        SkillItem(name: "Itinerary", emoji: "📋", selected: true),
        SkillItem(name: "Weather", emoji: "🌤️", selected: false),
        SkillItem(name: "Restaurant", emoji: "🍽️", selected: false),
    ]

    private let models = [
        ("Opus 4.6", "🧠"),
        ("Sonnet 4.5", "⚡"),
        ("Gemini Pro", "💎"),
    ]

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 6) {
                progressBar

                switch step {
                case 0: modelPickerStep
                case 1: skillsStep
                default: confirmStep
                }
            }
        }
        .onAppear { syncState() }
        .onChange(of: step) { _ in syncState() }
        .onChange(of: selectedModel) { _ in syncState() }
    }

    /// 同步 Watch UI 狀態到 iPhone → iPad/macOS
    private func syncState() {
        let selectedSkills = skills.filter(\.selected).map(\.name)
        connectivity.sendUIState([
            "flow": "agentConfig",
            "step": step,
            "selectedModel": models[selectedModel].0,
            "selectedModelEmoji": models[selectedModel].1,
            "selectedSkills": selectedSkills,
        ])
    }

    // MARK: - 進度條
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= step ? lobsterOrange : Color.gray.opacity(0.3))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Step 0: 選模型
    private var modelPickerStep: some View {
        VStack(spacing: 8) {
            Text("選擇模型")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            // 模型卡片滑選
            TabView(selection: $selectedModel) {
                ForEach(0..<models.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(models[i].1)
                            .font(.system(size: 28))
                        Text(models[i].0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        if i == 0 {
                            Text("推薦")
                                .font(.system(size: 9))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(lobsterOrange)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(teal.opacity(i == selectedModel ? 0.2 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(i == selectedModel ? teal : Color.clear, lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 8)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 100)

            Button(action: { withAnimation { step = 1 } }) {
                Text("下一步 →")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(lobsterOrange)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Step 1: 選技能
    private var skillsStep: some View {
        VStack(spacing: 4) {
            Text("選擇技能")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 2)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach($skills) { $skill in
                        Button(action: { skill.selected.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: skill.selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(skill.selected ? teal : .gray)
                                    .font(.system(size: 16))
                                Text("\(skill.emoji) \(skill.name)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 100)

            HStack(spacing: 8) {
                Button("← 返回") { withAnimation { step = 0 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button("確認 →") { withAnimation { step = 2 } }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .tint(lobsterOrange)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Step 2: 確認建立
    private var confirmStep: some View {
        VStack(spacing: 8) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 28))
                .foregroundColor(teal)

            Text("Trip Planner Agent")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("模型:")
                        .foregroundColor(.gray)
                    Text("\(models[selectedModel].1) \(models[selectedModel].0)")
                        .foregroundColor(.white)
                }
                .font(.system(size: 11))

                HStack(spacing: 4) {
                    Text("技能:")
                        .foregroundColor(.gray)
                    Text(skills.filter(\.selected).map(\.emoji).joined(separator: ""))
                        .foregroundColor(.white)
                }
                .font(.system(size: 11))
            }

            HStack(spacing: 8) {
                Button("← 返回") { withAnimation { step = 1 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button(action: {
                    let selectedSkills = skills.filter(\.selected).map(\.name).joined(separator: ", ")
                    let command = "Create a trip planner agent with \(models[selectedModel].0) and skills: \(selectedSkills)"
                    onComplete(command)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("建立")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(teal)
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - 技能資料模型
struct SkillItem: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var selected: Bool
}
