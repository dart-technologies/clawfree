import SwiftUI

// MARK: - 聲波動畫元件（V3 設計）

struct WaveformView: View {
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 20)
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 3, height: max(4, amplitudes[index] * 25))
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.2...0.4)),
                        value: amplitudes[index]
                    )
            }
        }
        .onReceive(timer) { _ in
            animateWaveform()
        }
        .onAppear {
            animateWaveform()
        }
    }
    
    private func animateWaveform() {
        for i in 0..<amplitudes.count {
            amplitudes[i] = CGFloat.random(in: 0.15...1.0)
        }
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView()
            .frame(height: 30)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
