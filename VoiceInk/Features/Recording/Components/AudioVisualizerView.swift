import SwiftUI

struct AudioVisualizer: View {
    let audioMeterProvider: () -> AudioMeter
    let color: Color
    let isActive: Bool

    private let barCount = 15
    private let barWidth: CGFloat = 3.2
    private let barSpacing: CGFloat = 2.5
    private let minHeight: CGFloat = 4.0
    private let maxHeight: CGFloat = 26.0

    private let phases: [Double]

    init(audioMeterProvider: @escaping () -> AudioMeter, color: Color, isActive: Bool) {
        self.audioMeterProvider = audioMeterProvider
        self.color = color
        self.isActive = isActive
        self.phases = (0..<barCount).map { Double($0) * 0.45 }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.40, green: 0.82, blue: 1.00),
                color,
                Color(red: 0.72, green: 0.55, blue: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let audioMeter = audioMeterProvider()

            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(barGradient)
                        .shadow(color: Color(red: 0.40, green: 0.75, blue: 1.0).opacity(0.35), radius: 2.5, x: 0, y: 0)
                        .frame(
                            width: barWidth,
                            height: barHeight(
                                for: index,
                                at: context.date,
                                audioMeter: audioMeter
                            )
                        )
                }
            }
        }
    }

    private func barHeight(for index: Int, at date: Date, audioMeter: AudioMeter) -> CGFloat {
        guard isActive else { return minHeight }

        let time = date.timeIntervalSince1970
        let center = Double(barCount - 1) / 2.0
        let normalizedDist = (Double(index) - center) / center
        let bellCurve = exp(-2.2 * normalizedDist * normalizedDist)

        let wave1 = sin(time * 5.2 + phases[index])
        let wave2 = cos(time * 3.4 - phases[index] * 0.8)
        let harmonicWave = (wave1 * 0.65 + wave2 * 0.35) * 0.5 + 0.5

        let rawPower = Double(max(0, min(1, audioMeter.averagePower)))
        let power = pow(rawPower, 0.65)

        let baseline = 0.14
        let dynamicEnergy = baseline + power * 0.86

        let heightFraction = bellCurve * (dynamicEnergy * 0.32 + dynamicEnergy * harmonicWave * 0.68)
        return max(minHeight, minHeight + CGFloat(heightFraction) * (maxHeight - minHeight))
    }
}

// Fluid breathing bars shown when the recorder is idle (waiting for input)
struct StaticVisualizer: View {
    private let barCount = 15
    private let barWidth: CGFloat = 3.2
    private let barSpacing: CGFloat = 2.5
    private let minHeight: CGFloat = 4.0
    private let maxHeight: CGFloat = 8.0
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { context in
            let time = context.date.timeIntervalSince1970
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    let center = Double(barCount - 1) / 2.0
                    let dist = abs(Double(index) - center) / center
                    let bell = exp(-1.8 * dist * dist)
                    let wave = sin(time * 2.2 + Double(index) * 0.42) * 0.5 + 0.5
                    let height = minHeight + CGFloat(bell * wave) * (maxHeight - minHeight)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.82, blue: 1.00).opacity(0.65),
                                    color.opacity(0.75),
                                    Color(red: 0.72, green: 0.55, blue: 1.00).opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: barWidth, height: height)
                }
            }
        }
    }
}

// MARK: - Processing Status Display

struct ProcessingStatusDisplay: View {
    enum Mode {
        case transcribing
        case enhancing
    }

    let mode: Mode
    let color: Color

    private var label: LocalizedStringKey {
        switch mode {
        case .transcribing: return "Transcribing"
        case .enhancing: return "Enhancing"
        }
    }

    private var animationSpeed: Double {
        switch mode {
        case .transcribing: return 0.18
        case .enhancing: return 0.22
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .foregroundColor(color)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            ProgressAnimation(color: color, animationSpeed: animationSpeed)
        }
        .frame(height: 28)  // matches AudioVisualizer maxHeight to prevent layout shift
    }
}
