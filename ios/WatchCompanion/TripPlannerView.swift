import SwiftUI

// MARK: - Trip planning flow (Watch)
// Steps: select destination → select days → select attractions → submit

struct TripPlannerView: View {
    @ObservedObject var connectivity: ConnectivityProvider
    var onComplete: (String) -> Void
    var onCancel: () -> Void

    private let lobsterOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let teal = Color(red: 0.0, green: 0.75, blue: 0.65)
    private let darkBg = Color(red: 0.1, green: 0.1, blue: 0.1)

    @State private var step = 0  // 0=destination, 1=days, 2=attractions, 3=confirm
    @State private var selectedCity = 0
    @State private var selectedDays = 1  // index into daysOptions
    @State private var attractions: [AttractionItem] = []

    private let cities = [
        CityCard(name: "Tokyo", emoji: "🗼", flag: "🇯🇵", color: Color.pink),
        CityCard(name: "Kyoto", emoji: "⛩️", flag: "🇯🇵", color: Color.orange),
        CityCard(name: "Osaka", emoji: "🏯", flag: "🇯🇵", color: Color.purple),
        CityCard(name: "Seoul", emoji: "🏙️", flag: "🇰🇷", color: Color.blue),
        CityCard(name: "Bangkok", emoji: "🛕", flag: "🇹🇭", color: Color.yellow),
    ]

    private let daysOptions = [3, 5, 7]

    // Attractions per city
    private let cityAttractions: [[AttractionItem]] = [
        // Tokyo
        [
            AttractionItem(name: "Senso-ji Temple", emoji: "⛩️", selected: true),
            AttractionItem(name: "Akihabara", emoji: "🎮", selected: true),
            AttractionItem(name: "Shibuya Crossing", emoji: "🚶", selected: false),
            AttractionItem(name: "Tsukiji Market", emoji: "🍣", selected: true),
            AttractionItem(name: "Mt. Fuji Day Trip", emoji: "🗻", selected: false),
        ],
        // Kyoto
        [
            AttractionItem(name: "Fushimi Inari", emoji: "⛩️", selected: true),
            AttractionItem(name: "Bamboo Grove", emoji: "🎋", selected: true),
            AttractionItem(name: "Golden Pavilion", emoji: "🏛️", selected: true),
            AttractionItem(name: "Geisha District", emoji: "🎭", selected: false),
        ],
        // Osaka
        [
            AttractionItem(name: "Osaka Castle", emoji: "🏯", selected: true),
            AttractionItem(name: "Dotonbori", emoji: "🏮", selected: true),
            AttractionItem(name: "Universal Studios", emoji: "🎢", selected: false),
            AttractionItem(name: "Street Food Tour", emoji: "🍢", selected: true),
        ],
        // Seoul
        [
            AttractionItem(name: "Gyeongbokgung", emoji: "🏛️", selected: true),
            AttractionItem(name: "Myeongdong", emoji: "🛍️", selected: true),
            AttractionItem(name: "N Seoul Tower", emoji: "🗼", selected: false),
            AttractionItem(name: "Korean BBQ Tour", emoji: "🥩", selected: true),
        ],
        // Bangkok
        [
            AttractionItem(name: "Grand Palace", emoji: "👑", selected: true),
            AttractionItem(name: "Floating Market", emoji: "🛶", selected: true),
            AttractionItem(name: "Chatuchak Market", emoji: "🏪", selected: false),
            AttractionItem(name: "Thai Cooking Class", emoji: "🍜", selected: true),
        ],
    ]

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 6) {
                progressBar

                switch step {
                case 0: cityStep
                case 1: daysStep
                case 2: attractionsStep
                default: summaryStep
                }
            }
        }
        .onAppear {
            attractions = cityAttractions[selectedCity]
            syncState()
            // TTS: "Where would you like to travel?"
            WatchTTSService.shared.speak("Where would you like to travel?")
        }
        .onChange(of: selectedCity) { newVal in
            if newVal < cityAttractions.count {
                attractions = cityAttractions[newVal]
            }
            syncState()
        }
        .onChange(of: step) { newStep in
            syncState()
            // TTS when entering days step
            if newStep == 1 {
                WatchTTSService.shared.speak("How many days?")
            }
        }
        .onChange(of: selectedDays) { _ in syncState() }
    }

    // MARK: - Progress bar
    private var progressBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= step ? teal : Color.gray.opacity(0.3))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    /// Sync Watch UI state to iPhone → iPad/macOS
    private func syncState() {
        let selectedAttr = attractions.filter(\.selected).map(\.name)
        connectivity.sendUIState([
            "flow": "tripPlanner",
            "step": step,
            "selectedCity": cities[selectedCity].name,
            "selectedCityEmoji": cities[selectedCity].emoji,
            "selectedDays": daysOptions[selectedDays],
            "selectedAttractions": selectedAttr,
        ])
    }

    // MARK: - Step 0: Select Destination
    private var cityStep: some View {
        VStack(spacing: 6) {
            Text("🌍 Where to?")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            TabView(selection: $selectedCity) {
                ForEach(0..<cities.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(cities[i].emoji)
                            .font(.system(size: 36))
                        Text(cities[i].flag + " " + cities[i].name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(cities[i].color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(cities[i].color.opacity(0.5), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal, 6)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 100)

            Button(action: { withAnimation { step = 1 } }) {
                Text("Select \(cities[selectedCity].name) →")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(cities[selectedCity].color)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Step 1: Select Duration
    private var daysStep: some View {
        VStack(spacing: 10) {
            Text("📅 How many days?")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            Text("\(cities[selectedCity].emoji) \(cities[selectedCity].name)")
                .font(.system(size: 11))
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                ForEach(0..<daysOptions.count, id: \.self) { i in
                    Button(action: { withAnimation { selectedDays = i } }) {
                        VStack(spacing: 2) {
                            Text("\(daysOptions[i])")
                                .font(.system(size: 22, weight: .bold))
                            Text("days")
                                .font(.system(size: 10))
                        }
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(i == selectedDays ? teal.opacity(0.3) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(i == selectedDays ? teal : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .foregroundColor(i == selectedDays ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button("← Back") { withAnimation { step = 0 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button("Next →") { withAnimation { step = 2 } }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .tint(teal)
            }
        }
    }

    // MARK: - Step 2: Select Attractions
    private var attractionsStep: some View {
        VStack(spacing: 4) {
            Text("📍 Select Attractions")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            ScrollView {
                VStack(spacing: 3) {
                    ForEach($attractions) { $attr in
                        Button(action: { attr.selected.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: attr.selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(attr.selected ? teal : .gray)
                                    .font(.system(size: 15))
                                Text("\(attr.emoji) \(attr.name)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 95)

            HStack(spacing: 8) {
                Button("← Back") { withAnimation { step = 1 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button("Plan →") { withAnimation { step = 3 } }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .tint(teal)
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Step 3: Confirm summary
    private var summaryStep: some View {
        VStack(spacing: 6) {
            Text(cities[selectedCity].emoji)
                .font(.system(size: 28))

            Text("\(cities[selectedCity].name) \(daysOptions[selectedDays]) days")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            let selected = attractions.filter(\.selected)
            Text(selected.map(\.emoji).joined(separator: " "))
                .font(.system(size: 16))

            Text("\(selected.count) attractions")
                .font(.system(size: 10))
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                Button("← Edit") { withAnimation { step = 2 } }
                    .font(.system(size: 11))
                    .buttonStyle(.bordered)

                Button(action: {
                    let selectedAttr = attractions.filter(\.selected).map(\.name).joined(separator: ", ")
                    let command = "Plan a \(daysOptions[selectedDays]) day trip to \(cities[selectedCity].name) including \(selectedAttr)"
                    onComplete(command)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                        Text("Start Planning")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(lobsterOrange)
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Data models
struct CityCard {
    let name: String
    let emoji: String
    let flag: String
    let color: Color
}

struct AttractionItem: Identifiable {
    let id = UUID()
    var name: String
    var emoji: String
    var selected: Bool
}
