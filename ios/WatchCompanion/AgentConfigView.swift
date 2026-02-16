import SwiftUI

// MARK: - Agent creation flow (Watch)
// Steps: select model → select skills → confirm

struct AgentConfigView: View {
    @ObservedObject var connectivity: ConnectivityProvider
    var onComplete: (String) -> Void  // Returns command text on completion
    var onCancel: () -> Void

    // Brand colors
    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal = Color(red: 0.0, green: 0.75, blue: 0.65)
    private let darkBg = Color(red: 0.1, green: 0.1, blue: 0.1)

    // Step state
    @State private var step = 0  // 0=model, 1=skills, 2=confirm
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
        .onAppear {
            syncState()
            // TTS: "What model would you like to use?"
            WatchTTSService.shared.speak("What model would you like to use?")
        }
        .onChange(of: step) { newStep in
            syncState()
            // TTS when entering skills step
            if newStep == 1 {
                WatchTTSService.shared.speak("What skills should this agent have?")
            }
        }
        .onChange(of: selectedModel) { _ in syncState() }
    }

    /// Sync Watch UI state to iPhone → iPad/macOS
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

    // MARK: - Progress bar
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

    // MARK: - Step 0: Select Model
    private var modelPickerStep: some View {
        VStack(spacing: 8) {
            Text("Select Model")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            // Model card carousel
            TabView(selection: $selectedModel) {
                ForEach(0..<models.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(models[i].1)
                            .font(.system(size: 28))
                        Text(models[i].0)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        if i == 0 {
                            Text("Recommended")
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
                Text("Next →")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(lobsterOrange)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Step 1: Select Skills
    private var skillsStep: some View {
        VStack(spacing: 4) {
            Text("Select Skills")
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
                Button("← Back") { withAnimation { step = 0 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button("Confirm →") { withAnimation { step = 2 } }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .tint(lobsterOrange)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Step 2: Confirm creation
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
                    Text("Model:")
                        .foregroundColor(.gray)
                    Text("\(models[selectedModel].1) \(models[selectedModel].0)")
                        .foregroundColor(.white)
                }
                .font(.system(size: 11))

                HStack(spacing: 4) {
                    Text("Skills:")
                        .foregroundColor(.gray)
                    Text(skills.filter(\.selected).map(\.emoji).joined(separator: ""))
                        .foregroundColor(.white)
                }
                .font(.system(size: 11))
            }

            HStack(spacing: 8) {
                Button("← Back") { withAnimation { step = 1 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button(action: {
                    let selectedSkills = skills.filter(\.selected).map(\.name).joined(separator: ", ")
                    let command = "Create a trip planner agent with \(models[selectedModel].0) and skills: \(selectedSkills)"
                    onComplete(command)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Create")
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

// MARK: - Skill data model
struct SkillItem: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var selected: Bool
}
