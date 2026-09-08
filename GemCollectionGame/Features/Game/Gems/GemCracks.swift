import Foundation
import GameplayKit

/// Convex combinations keep every fracture point inside the actual gem polygon.
enum GemCracks {
    static func generate(sides: Int, rotation: Double, maximumFractures: Int,
                         random: GKRandomSource) -> [[SurfacePoint]] {
        guard maximumFractures > 0 else { return [] }
        func unit() -> Double { Double(random.nextUniform()) }
        func mix(_ a: SurfacePoint, _ b: SurfacePoint, _ t: Double) -> SurfacePoint {
            SurfacePoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        let center = SurfacePoint(x: 0.5, y: 0.5)
        let vertices = (0..<sides).map { index in
            let angle = rotation + Double(index) * .pi * 2 / Double(sides)
            return SurfacePoint(x: 0.5 + cos(angle) * 0.46, y: 0.5 + sin(angle) * 0.46)
        }
        func edgePoint(_ edge: Int) -> SurfacePoint {
            mix(vertices[edge % sides], vertices[(edge + 1) % sides], 0.12 + unit() * 0.76)
        }
        let baseCount = 1 + min(maximumFractures - 1, Int(unit() * Double(maximumFractures)))
        let extra = Double(baseCount) * 0.20
        let count = baseCount + Int(extra) + (unit() < extra - floor(extra) ? 1 : 0)
        var paths: [[SurfacePoint]] = []
        for _ in 0..<count {
            let edge = min(sides - 1, Int(unit() * Double(sides)))
            let start = edgePoint(edge)
            let opposite = (edge + 1 + Int(unit() * Double(sides - 1))) % sides
            let end = mix(edgePoint(opposite), center, unit() < 0.5 ? 0 : 0.35 + unit() * 0.35)
            let bends = 2 + Int(unit() * 3)
            var path = [start]
            for step in 1...bends {
                let t = Double(step) / Double(bends + 1)
                let chord = mix(start, end, t)
                let inward = mix(center, edgePoint((edge + step) % sides), unit() * 0.4)
                path.append(mix(chord, inward, 0.08 + unit() * 0.32))
            }
            path.append(end)
            paths.append(path)
            if unit() < 0.55 {
                let junction = path[1 + Int(unit() * Double(bends))]
                let tip = mix(center, edgePoint((edge + 1) % sides), 0.35 + unit() * 0.45)
                paths.append([junction, mix(mix(junction, tip, 0.5), center, 0.15), tip])
            }
        }
        return paths
    }
}
