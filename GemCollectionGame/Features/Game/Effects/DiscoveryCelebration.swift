import SwiftUI

struct DiscoveryCelebration: ViewModifier {
    let event: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var haptics = DiscoveryHaptics()
    @State private var startedAt: Date?
    @State private var shakeProgress = 0.0

    func body(content: Content) -> some View {
        content
            .modifier(DiscoveryShake(progress: shakeProgress, enabled: !reduceMotion))
            .overlay {
                if let startedAt, !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                        DiscoveryConfettiFrame(progress: min(1,
                            timeline.date.timeIntervalSince(startedAt) / DiscoveryConfettiFrame.duration))
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .clipped()
            .onChange(of: event) { _ in
                guard scenePhase == .active else { return }
                haptics.play()
                guard !reduceMotion else { return }
                startedAt = Date()
                withAnimation(.linear(duration: DiscoveryShake.duration)) { shakeProgress += 1 }
            }
            .task(id: startedAt) {
                guard startedAt != nil else { return }
                do {
                    try await Task.sleep(nanoseconds: UInt64(DiscoveryConfettiFrame.duration * 1_000_000_000))
                } catch { return }
                startedAt = nil
            }
            .onChange(of: reduceMotion) { reduced in
                if reduced { startedAt = nil }
            }
            .onChange(of: scenePhase) { phase in
                if phase != .active { startedAt = nil; haptics.stop() }
            }
            .onDisappear { haptics.stop() }
    }
}

struct DiscoveryShake: GeometryEffect {
    static let duration = 0.42
    var progress: Double
    var enabled = true
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    static func offset(at progress: Double) -> CGSize {
        guard progress > 0, progress < 1 else { return .zero }
        let amplitude = 7 * pow(1 - progress, 1.5)
        return CGSize(width: sin(progress * .pi * 18) * amplitude,
                      height: sin(progress * .pi * 24) * amplitude * 0.55)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = enabled ? Self.offset(at: progress - floor(progress)) : .zero
        return ProjectionTransform(CGAffineTransform(translationX: offset.width, y: offset.height))
    }
}

struct DiscoveryConfettiFrame: View {
    static let duration = 1.25
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let colors: [Color] = [.purple, .yellow, .mint, .cyan, .pink]
            let travel = 1 - pow(1 - progress, 2)
            for corner in 0..<4 {
                let left = corner.isMultiple(of: 2)
                let top = corner < 2
                let origin = CGPoint(x: left ? 0 : size.width, y: top ? 0 : size.height)
                for index in 0..<24 {
                    let seed = index * 17 + corner * 11
                    let horizontal = 0.18 + Double(seed % 19) / 45
                    let vertical = 0.18 + Double((seed * 7) % 23) / 65
                    var particle = context
                    particle.opacity = min(1, max(0, (1 - progress) / 0.28))
                    particle.translateBy(
                        x: origin.x + (left ? 1 : -1) * size.width * horizontal * travel,
                        y: origin.y + (top ? 1 : -1) * size.height * vertical * travel + size.height * 0.16 * progress * progress)
                    particle.rotate(by: .radians(Double(seed) + progress * Double(index % 2 == 0 ? 9 : -9)))
                    let width = 3 + Double(index % 3)
                    let height = 7 + Double(index % 4)
                    particle.scaleBy(x: 0.45 + abs(cos(progress * 12 + Double(seed))) * 0.55, y: 1)
                    particle.fill(Path(CGRect(x: -width / 2, y: -height / 2, width: width, height: height)),
                                  with: .color(colors[seed % colors.count]))
                }
            }
        }
    }
}
