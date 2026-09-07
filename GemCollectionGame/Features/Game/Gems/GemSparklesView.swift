import SwiftUI

/// Only the small glint layer updates; the gem's faceted body remains static.
struct GemSparklesView: View {
    let gem: Gem
    let animated: Bool
    private let timings: [SparkleTiming]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    init(gem: Gem, animated: Bool) {
        self.gem = gem
        self.animated = animated
        timings = gem.sparkles.indices.map { SparkleTiming(seed: gem.seed, index: $0) }
    }

    var body: some View {
        Group {
            if reduceMotion || !animated {
                glints(time: nil)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: scenePhase != .active)) { timeline in
                    glints(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func glints(time: TimeInterval?) -> some View {
        Canvas { context, size in
            for (index, sparkle) in gem.sparkles.enumerated() {
                let brightness = time.map { timings[index].brightness(at: $0) } ?? 1
                guard brightness > 0.001 else { continue }
                let center = CGPoint(x: sparkle.x * size.width, y: (sparkle.y * 0.86 + 0.02) * size.height)
                let storedSize = gem.sparkleSizes.flatMap { index < $0.count ? $0[index] : nil }
                let radius = size.width * (storedSize ?? (index == 0 ? 0.11 : 0.055)) * (0.65 + brightness * 0.35)
                var light = context
                light.opacity = brightness
                light.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                  width: radius * 2, height: radius * 2)),
                           with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .clear]),
                                                 center: center, startRadius: 0, endRadius: radius))
                var star = Path()
                star.addLines([CGPoint(x: center.x, y: center.y - radius),
                               CGPoint(x: center.x + radius * 0.18, y: center.y - radius * 0.18),
                               CGPoint(x: center.x + radius, y: center.y),
                               CGPoint(x: center.x + radius * 0.18, y: center.y + radius * 0.18),
                               CGPoint(x: center.x, y: center.y + radius),
                               CGPoint(x: center.x - radius * 0.18, y: center.y + radius * 0.18),
                               CGPoint(x: center.x - radius, y: center.y),
                               CGPoint(x: center.x - radius * 0.18, y: center.y - radius * 0.18)])
                star.closeSubpath()
                light.fill(star, with: .color(.white.opacity(0.95)))
            }
        }
    }
}
