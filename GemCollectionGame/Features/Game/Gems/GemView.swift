import SwiftUI

struct GemView: View {
    let gem: Gem

    var body: some View {
        Canvas { context, size in
            func point(_ p: SurfacePoint) -> CGPoint {
                CGPoint(x: p.x * size.width, y: (p.y * 0.86 + 0.02) * size.height)
            }
            func polygon(_ points: [CGPoint]) -> Path {
                var path = Path()
                path.addLines(points)
                path.closeSubpath()
                return path
            }
            func color(light: Double = 0, alpha: Double = 1) -> Color {
                func channel(_ value: Double) -> Double {
                    light >= 0 ? value + (1 - value) * light : value * (1 + light)
                }
                return Color(red: channel(gem.color.red), green: channel(gem.color.green),
                             blue: channel(gem.color.blue), opacity: alpha)
            }
            let rim = (0..<gem.shape.sides).map { index in
                let angle = gem.rotation + Double(index) * .pi * 2 / Double(gem.shape.sides)
                return point(.init(x: 0.5 + cos(angle) * 0.46, y: 0.5 + sin(angle) * 0.46))
            }
            let center = point(.init(x: 0.47, y: 0.44))
            let inner = rim.map { CGPoint(x: center.x + ($0.x - center.x) * 0.58,
                                         y: center.y + ($0.y - center.y) * 0.58) }
            let base = rim.map { CGPoint(x: $0.x, y: $0.y + size.height * 0.09) }
            var shadow = context
            shadow.translateBy(x: size.width * 0.025, y: size.height * 0.035)
            shadow.fill(polygon(base), with: .color(.black.opacity(0.5)))
            context.fill(polygon(base), with: .color(color(light: -0.67)))
            for i in rim.indices {
                let j = (i + 1) % rim.count
                context.fill(polygon([rim[i], rim[j], base[j], base[i]]),
                             with: .linearGradient(Gradient(colors: [color(light: -0.20), color(light: -0.65)]),
                                                   startPoint: rim[i], endPoint: base[i]))
                let lighting = (0.5 - Double((rim[i].x + rim[j].x) / (2 * size.width))) * 0.5 +
                               (0.5 - Double((rim[i].y + rim[j].y) / (2 * size.height))) * 0.65
                context.fill(polygon([rim[i], rim[j], inner[j], inner[i]]),
                             with: .color(color(light: lighting)))
            }
            context.fill(polygon(inner), with: .linearGradient(
                Gradient(colors: [color(light: 0.24), color(light: -0.08)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            for i in inner.indices {
                var facetEdge = Path()
                facetEdge.move(to: rim[i])
                facetEdge.addLine(to: inner[i])
                context.stroke(facetEdge, with: .color(color(light: 0.5, alpha: 0.22)), lineWidth: size.width * 0.012)
            }
            context.stroke(polygon(rim), with: .linearGradient(
                Gradient(colors: [color(light: 0.6, alpha: 0.8), color(light: -0.5)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: size.width * 0.018)

            var surface = context
            surface.clip(to: polygon(rim))
            for points in gem.crackPaths {
                var crack = Path()
                crack.addLines(points.map(point))
                var lip = surface
                lip.translateBy(x: size.width * 0.018, y: size.height * 0.012)
                lip.stroke(crack, with: .color(color(light: 0.55, alpha: 0.65)),
                           style: StrokeStyle(lineWidth: size.width * 0.018, lineJoin: .bevel))
                surface.stroke(crack, with: .color(color(light: -0.85)),
                               style: StrokeStyle(lineWidth: size.width * 0.035, lineCap: .round, lineJoin: .bevel))
            }
            if !gem.sparkles.isEmpty {
                surface.fill(polygon(inner), with: .linearGradient(
                    Gradient(stops: [.init(color: .clear, location: 0.25),
                                     .init(color: .white.opacity(0.42), location: 0.40),
                                     .init(color: .clear, location: 0.54)]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height * 0.7)))
            }
            for (index, sparkle) in gem.sparkles.enumerated() {
                let center = point(sparkle)
                let radius = size.width * (index == 0 ? 0.11 : 0.055)
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                    width: radius * 2, height: radius * 2)),
                             with: .radialGradient(Gradient(colors: [.white.opacity(0.5), .clear]),
                                                   center: center, startRadius: 0, endRadius: radius))
                let star = polygon([CGPoint(x: center.x, y: center.y - radius),
                                    CGPoint(x: center.x + radius * 0.18, y: center.y - radius * 0.18),
                                    CGPoint(x: center.x + radius, y: center.y),
                                    CGPoint(x: center.x + radius * 0.18, y: center.y + radius * 0.18),
                                    CGPoint(x: center.x, y: center.y + radius),
                                    CGPoint(x: center.x - radius * 0.18, y: center.y + radius * 0.18),
                                    CGPoint(x: center.x - radius, y: center.y),
                                    CGPoint(x: center.x - radius * 0.18, y: center.y - radius * 0.18)])
                context.fill(star, with: .color(.white.opacity(0.95)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// All combinations are inspectable in Xcode's preview without changing the saved game.
#Preview("Gem Catalog") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(PopulationConfiguration.standard.grades) { grade in
                Text(grade.name).font(.headline)
                ForEach(PopulationConfiguration.standard.colors) { color in
                    HStack {
                        ForEach(PopulationConfiguration.standard.shapes) { shape in
                            GemView(gem: Gem(id: shape.sides, seed: 42, grade: grade, color: color, shape: shape))
                                .frame(width: 64, height: 64)
                        }
                    }
                }
            }
        }.padding()
    }.background(Color(white: 0.06)).preferredColorScheme(.dark)
}
