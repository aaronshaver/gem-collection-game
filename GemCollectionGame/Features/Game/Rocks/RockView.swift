import SwiftUI

struct RockView: View {
    let rock: Rock

    var body: some View {
        Canvas { context, size in
            let gray = rock.gray - 0.09
            func point(_ p: Rock.Point) -> CGPoint {
                CGPoint(x: p.x * size.width, y: (p.y * 0.84 + 0.025) * size.height)
            }
            func polygon(_ points: [CGPoint]) -> Path {
                var path = Path()
                path.addLines(points)
                path.closeSubpath()
                return path
            }
            func mix(_ a: CGPoint, _ b: CGPoint, _ amount: CGFloat) -> CGPoint {
                CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
            }
            let rim = rock.outline.map(point)
            guard rim.count > 2 else { return }
            let depth = size.height * 0.115
            let base = rim.map { CGPoint(x: $0.x, y: $0.y + depth) }
            let center = point(.init(x: 0.47, y: 0.43))
            let crown = rim.map { mix($0, center, 0.24) }

            var shadow = context
            shadow.translateBy(x: size.width * 0.035, y: size.height * 0.045)
            shadow.fill(polygon(base), with: .color(.black.opacity(0.45)))

            // Extruded side walls remain visible below the illuminated top face.
            context.fill(polygon(base), with: .color(Color(white: gray - 0.25)))
            for i in rim.indices {
                let j = (i + 1) % rim.count
                let face = polygon([rim[i], rim[j], base[j], base[i]])
                let light = 0.09 * (1 - rim[i].x / size.width)
                context.fill(face, with: .linearGradient(
                    Gradient(colors: [Color(white: gray - 0.12 + light),
                                      Color(white: gray - 0.30 + light)]),
                    startPoint: rim[i], endPoint: base[i]))
            }
            let silhouette = polygon(rim)
            context.fill(silhouette, with: .radialGradient(
                Gradient(colors: [Color(white: gray + 0.23), Color(white: gray + 0.04),
                                  Color(white: gray - 0.19)]),
                center: point(rock.highlight), startRadius: 0, endRadius: size.width * 0.70))

            // Broad bevel facets give chipped edges volume instead of a flat outline.
            for i in rim.indices {
                let j = (i + 1) % rim.count
                let face = polygon([rim[i], rim[j], crown[j], crown[i]])
                let mid = mix(rim[i], rim[j], 0.5)
                let illumination = (center.x - mid.x + center.y - mid.y) / size.width
                context.fill(face, with: .color(illumination > 0
                    ? .white.opacity(Double(illumination) * 0.40)
                    : .black.opacity(Double(-illumination) * 0.55 + 0.04)))
            }
            context.clip(to: silhouette)
            for chip in rock.chips {
                context.fill(polygon(chip.points.map(point)), with: .color(.black.opacity(chip.shade)))
                if chip.points.count >= 4 {
                    var lip = Path()
                    lip.move(to: point(chip.points[2]))
                    lip.addLine(to: point(chip.points[3]))
                    context.stroke(lip, with: .color(.white.opacity(0.22)), lineWidth: size.width * 0.012)
                }
            }
            for fleck in rock.flecks {
                let center = point(fleck.center)
                let radius = fleck.radius * size.width
                let mark = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                 width: radius * 2, height: radius * 1.4))
                context.fill(mark, with: .color(fleck.isLight ? .white.opacity(0.14) : .black.opacity(0.15)))
            }
            context.stroke(silhouette, with: .linearGradient(
                Gradient(colors: [.white.opacity(0.30), .black.opacity(0.25)]),
                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)),
                lineWidth: size.width * 0.014)
        }
        .accessibilityHidden(true)
    }
}
