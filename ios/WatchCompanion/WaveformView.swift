import SwiftUI

// MARK: - V1 Wave Animation (5 bars, matching HTML prototype)

struct WaveformView: View {
    @State private var animating = false

    private let barCount = 5
    private let baseHeights: [CGFloat] = [10, 18, 28, 18, 10]
    private let delays: [Double] = [0, 0.1, 0.2, 0.3, 0.4]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.49, blue: 0.92),
                                Color(red: 0.46, green: 0.29, blue: 0.64)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: baseHeights[index])
                    .scaleEffect(y: animating ? 1.5 : 1.0, anchor: .center)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(delays[index]),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView()
            .frame(height: 35)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
