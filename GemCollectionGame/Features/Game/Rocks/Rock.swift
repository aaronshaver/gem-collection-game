import Foundation
import GameplayKit

/// Versioned, serializable appearance data; rendering never draws random values.
struct Rock: Identifiable, Codable, Equatable {
    typealias Point = SurfacePoint

    struct Chip: Codable, Equatable {
        let points: [Point]
        let shade: Double
    }

    struct Fleck: Codable, Equatable {
        let center: Point
        let radius: Double
        let isLight: Bool
    }

    let id: Int
    let seed: UInt64
    let generationVersion: Int
    let outline: [Point]
    let gray: Double
    let highlight: Point
    let chips: [Chip]
    let flecks: [Fleck]

    init(id: Int, seed: UInt64) {
        self.id = id
        self.seed = seed
        generationVersion = 2
        let random = GKLinearCongruentialRandomSource(seed: seed)
        func value(_ lower: Double, _ upper: Double) -> Double {
            lower + Double(random.nextUniform()) * (upper - lower)
        }
        gray = value(0.43, 0.55)
        highlight = Point(x: value(0.27, 0.40), y: value(0.22, 0.34))
        let rotation = value(0, .pi * 2)
        let squash = value(0.86, 1.0)
        outline = (0..<16).map { index in
            let angle = rotation + Double(index) * .pi * 2 / 16
            let radius = value(0.37, 0.49)
            return Point(x: 0.5 + cos(angle) * radius,
                         y: 0.5 + sin(angle) * radius * squash)
        }
        chips = (0..<3).map { index in
            let angle = rotation + Double(index) * 2.1 + value(-0.3, 0.3)
            func point(_ offset: Double, _ radius: Double) -> Point {
                Point(x: 0.5 + cos(angle + offset) * radius,
                      y: 0.5 + sin(angle + offset) * radius * squash)
            }
            return Chip(points: [point(-0.20, 0.48), point(0.18, 0.48),
                                 point(0.07, value(0.29, 0.37)), point(-0.14, 0.39)],
                        shade: value(0.08, 0.19))
        }
        flecks = (0..<28).map { _ in
            let angle = value(0, .pi * 2)
            let radius = sqrt(value(0, 1)) * 0.44
            return Fleck(center: Point(x: 0.5 + cos(angle) * radius,
                                       y: 0.5 + sin(angle) * radius),
                         radius: value(0.004, 0.014), isLight: random.nextBool())
        }
    }
}
