import SwiftUI

/// A short-lived layer: large polygon wedges split into smaller falling shards.
struct CollectionBurst: View {
    static let duration = 0.45
    let gem: Gem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date()
    @State private var faded = false

    var body: some View {
        Group {
            if reduceMotion {
                GemView(gem: gem, animateSparkles: false)
                    .opacity(faded ? 0 : 1)
                    .onAppear { withAnimation(.easeOut(duration: 0.20)) { faded = true } }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    CollectionShatterFrame(gem: gem, progress: min(1, max(0,
                        timeline.date.timeIntervalSince(startedAt) / Self.duration)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Separating the frame renderer also makes every stage inspectable without a running animation.
struct CollectionShatterFrame: View {
    let gem: Gem
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, _ in
                let size = geometry.size
                let scale = gem.grade.id == "shiny" ? 1.05 : gem.grade.id == "cracked" ? 0.90 : 1
                let radius = size.width * 0.46 * scale
                let center = CGPoint(x: size.width * 2, y: size.height * 1.95)
                let vertices = (0..<gem.shape.sides).map { index in
                    let angle = gem.rotation + Double(index) * .pi * 2 / Double(gem.shape.sides)
                    return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius * 0.86)
                }
                let blast = 1 - pow(1 - min(1, progress / 0.38), 3)
                let fall = max(0, (progress - 0.30) / 0.70)
                let split = 0.32
                let fragmentProgress = max(0, (progress - split) / (1 - split))
                let opacity = min(1, (1 - progress) / 0.25)
                let darkness = gem.grade.id == "cracked" ? 0.88 : 1
                let color = Color(red: gem.color.red * darkness, green: gem.color.green * darkness,
                                  blue: gem.color.blue * darkness)
                CollectionSparks.draw(in: &context, center: center, size: size.width * 0.65,
                                      color: color, seed: gem.seed, progress: progress)
                for index in vertices.indices {
                    let triangle = [CGPoint.zero, vertices[index], vertices[(index + 1) % vertices.count]]
                    let centroid = CGPoint(x: triangle.map(\.x).reduce(0, +) / 3,
                                           y: triangle.map(\.y).reduce(0, +) / 3)
                    let fragments = progress < split ? [triangle] : (0..<3).map { edge in
                        [triangle[edge], triangle[(edge + 1) % 3], centroid]
                    }
                    for (fragmentIndex, points) in fragments.enumerated() {
                        let fragmentCenter = CGPoint(x: points.map(\.x).reduce(0, +) / 3,
                                                     y: points.map(\.y).reduce(0, +) / 3)
                        var shard = context
                        shard.opacity = max(0, opacity)
                        // A fast outward impulse comes first; gravity takes over after the blast.
                        let spread = Double(fragmentIndex - 1) * fragmentProgress * size.width * 0.12
                        shard.translateBy(x: center.x + centroid.x * blast * 0.85 + spread,
                                          y: center.y + centroid.y * blast * 0.85 + size.height * (-0.12 * blast + 0.75 * fall * fall))
                        shard.translateBy(x: centroid.x, y: centroid.y)
                        shard.rotate(by: .radians(Double(index % 2 == 0 ? 1 : -1) * progress * 1.2))
                        shard.translateBy(x: fragmentCenter.x - centroid.x, y: fragmentCenter.y - centroid.y)
                        shard.rotate(by: .radians(Double(fragmentIndex - 1) * fragmentProgress * 1.8))
                        let shrink = 1 - fragmentProgress * 0.80
                        shard.scaleBy(x: shrink, y: shrink)
                        var path = Path()
                        path.addLines(points.map { CGPoint(x: $0.x - fragmentCenter.x, y: $0.y - fragmentCenter.y) })
                        path.closeSubpath()
                        shard.fill(path, with: .linearGradient(
                            Gradient(colors: [color, color.opacity(0.75)]),
                            startPoint: CGPoint(x: -radius, y: -radius), endPoint: CGPoint(x: radius, y: radius)))
                        shard.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 0.7)
                    }
                }
            }
            // Keep falling shards inside the drawing surface even after they leave their cell.
            .frame(width: geometry.size.width * 4, height: geometry.size.height * 4)
            .offset(x: -geometry.size.width * 1.5, y: -geometry.size.height * 1.5)
        }
    }
}
