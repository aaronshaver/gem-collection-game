import SwiftUI

/// A brief impact glow and seeded spark trails, confined to the collection's existing timeline.
enum CollectionSparks {
    static func draw(in context: inout GraphicsContext, center: CGPoint, size: Double,
                     color: Color, seed: UInt64, progress: Double) {
        let flash = max(0, 1 - progress / 0.24)
        if flash > 0 {
            let radius = size * (0.35 + progress * 2)
            var glow = context
            glow.blendMode = .plusLighter
            glow.opacity = flash * 0.85
            glow.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                            width: radius * 2, height: radius * 2)),
                      with: .radialGradient(Gradient(colors: [.white, color.opacity(0.8), .clear]),
                                            center: center, startRadius: 0, endRadius: radius))
        }
        let fade = max(0, 1 - progress / 0.72)
        guard fade > 0 else { return }
        var sparks = context
        sparks.blendMode = .plusLighter
        sparks.opacity = fade
        let rotation = Double(seed % 1000) / 1000 * .pi * 2
        for index in 0..<20 {
            let angle = rotation + Double(index) * .pi * 2 / 20
            let speed = 0.85 + Double((index * 7) % 11) / 11 * 0.55
            let travel = size * (0.12 + (1 - pow(1 - progress, 3)) * speed)
            let drop = size * max(0, progress - 0.25) * max(0, progress - 0.25)
            let tip = CGPoint(x: center.x + cos(angle) * travel,
                              y: center.y + sin(angle) * travel + drop)
            let length = size * (0.06 + fade * 0.10)
            var trail = Path()
            trail.move(to: CGPoint(x: tip.x - cos(angle) * length, y: tip.y - sin(angle) * length))
            trail.addLine(to: tip)
            sparks.stroke(trail, with: .linearGradient(Gradient(colors: [color.opacity(0.1), color, .white]),
                startPoint: CGPoint(x: tip.x - cos(angle) * length, y: tip.y - sin(angle) * length), endPoint: tip),
                style: StrokeStyle(lineWidth: size * (index.isMultiple(of: 3) ? 0.022 : 0.012), lineCap: .round))
        }
    }
}
