import SwiftUI

/// Command picker sheet — replaces real voice recording in simulator.
/// User selects a command, then it's sent to iPhone via mock connectivity.
struct CommandPickerView: View {
    let onSelect: (String, String, [String: Any]) -> Void  // (command, displayText, params)
    @Environment(\.dismiss) private var dismiss

    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal = Color(red: 0.0, green: 0.75, blue: 0.65)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Select Command")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                // Plan a Trip
                Button(action: {
                    onSelect("plan_a_trip", "Plan a 3 day trip to Tokyo", [
                        "city": "Tokyo",
                        "days": 3
                    ])
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Plan a Trip")
                                .font(.system(size: 13, weight: .semibold))
                            Text("3 days in Tokyo")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(teal)

                // Create an Agent
                Button(action: {
                    onSelect("create_agent", "Create a Trip Planner agent with Claude Opus", [
                        "name": "Trip Planner",
                        "model": "Opus 4.6",
                        "skills": ["travel", "planning"]
                    ])
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create an Agent")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Trip Planner with Claude")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(lobsterOrange)

                // Free text
                Button(action: {
                    onSelect("voice_command", "What's the weather in Tokyo?", [:])
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask a Question")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Weather in Tokyo?")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(.horizontal, 4)
        }
    }
}
