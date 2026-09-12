import SwiftUI

/// Shared by board actions: a brief burst of flying rock and dirt.
/// Place in a cell-sized frame; the drawing surface extends beyond it for the debris.
struct DestructionEffect: View {
    static let duration = 0.36
    @State private var startedAt = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
            DestructionFrame(
                progress: min(0.65, timeline.date.timeIntervalSince(startedAt) / Self.duration * 0.65),
                reduceMotion: reduceMotion)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Deterministic frames let any future tool reuse the effect without owning its particles.
struct DestructionFrame: View {
    let progress: Double
    var reduceMotion = false

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let unit = size.width / 4 * 0.60
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                drawDirt(in: context, center: center, unit: unit)
                drawShards(in: context, center: center, unit: unit)
            }
            .frame(width: geometry.size.width * 4, height: geometry.size.height * 4)
            .offset(x: -geometry.size.width * 1.5, y: -geometry.size.height * 1.5)
        }
    }

    private func drawDirt(in context: GraphicsContext, center: CGPoint, unit: Double) {
        guard !reduceMotion else { return }
        let blast = 1 - pow(1 - min(1, progress / 0.55), 3)
        for index in 0..<44 {
            var particle = context
            particle.opacity = max(0, 1 - progress / 0.65)
            let angle = Double(index) * 2.39996
            let distance = unit * blast * (0.4 + Double(index % 9) * 0.11)
            let radius = unit * (0.018 + Double(index % 4) * 0.009)
            let point = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance + unit * progress * progress)
            particle.fill(
                Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius * 2, height: radius)),
                with: .color(Color(red: 0.36 + Double(index % 3) * 0.07, green: 0.22, blue: 0.10)))
        }
    }

    private func drawShards(in context: GraphicsContext, center: CGPoint, unit: Double) {
        guard !reduceMotion else { return }
        let blast = 1 - pow(1 - min(1, progress / 0.7), 3)
        for index in 0..<15 {
            var shard = context
            shard.opacity = max(0, min(1, (0.65 - progress) / 0.22))
            let angle = Double(index) * 2.39996
            let distance = unit * (0.1 + blast * (0.6 + Double(index % 4) * 0.2))
            shard.translateBy(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance + unit * progress * progress * 1.3)
            shard.rotate(by: .radians(angle + progress * Double(index % 2 == 0 ? 7 : -7)))
            let radius = unit * (0.065 + Double(index % 4) * 0.019) * (1 - progress * 0.5)
            var path = Path()
            path.addLines([
                CGPoint(x: -radius, y: -radius * 0.5), CGPoint(x: radius * 0.1, y: -radius),
                CGPoint(x: radius, y: -radius * 0.2), CGPoint(x: radius * 0.6, y: radius),
                CGPoint(x: -radius * 0.7, y: radius * 0.5),
            ])
            path.closeSubpath()
            let color =
                index.isMultiple(of: 3)
                ? Color(red: 0.29, green: 0.17, blue: 0.08) : Color(white: 0.30 + Double(index % 4) * 0.10)
            shard.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [color, color.opacity(0.6)]),
                    startPoint: CGPoint(x: 0, y: -radius),
                    endPoint: CGPoint(x: 0, y: radius)))
            shard.stroke(path, with: .color(.black.opacity(0.45)), lineWidth: 0.7)
        }
    }

}
