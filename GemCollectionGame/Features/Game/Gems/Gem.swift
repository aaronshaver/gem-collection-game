import Foundation
import GameplayKit

/// All appearance choices belong to the object, not to a view's render cycle.
struct Gem: Identifiable, Codable, Equatable {
    let id: Int
    let seed: UInt64
    let generationVersion: Int
    let grade: GemGrade
    let color: GemColor
    let shape: GemShape
    let rotation: Double
    let crackPaths: [[SurfacePoint]]
    let sparkles: [SurfacePoint]
    let sparkleSizes: [Double]?

    init(id: Int, seed: UInt64, grade: GemGrade, color: GemColor, shape: GemShape) {
        self.id = id
        self.seed = seed
        self.grade = grade
        self.color = color
        self.shape = shape
        generationVersion = 4
        let random = GKMersenneTwisterRandomSource(seed: seed)
        func unit() -> Double { Double(random.nextUniform()) }
        let orientation = unit() * Double.pi * 2
        rotation = orientation
        crackPaths = GemCracks.generate(sides: shape.sides, rotation: orientation,
                                         maximumFractures: grade.crackCount, random: random)
        let sparkleCount = grade.sparkleCount > 0 ? grade.sparkleCount + random.nextInt(upperBound: 4) : 0
        let vertices = (0..<shape.sides).map { index in
            let angle = orientation + Double(index) * .pi * 2 / Double(shape.sides)
            return SurfacePoint(x: 0.5 + cos(angle) * 0.46, y: 0.5 + sin(angle) * 0.46)
        }
        sparkles = (0..<sparkleCount).map { _ in
            let edge = random.nextInt(upperBound: shape.sides)
            let t = unit()
            let a = vertices[edge], b = vertices[(edge + 1) % shape.sides]
            let inward = 0.30 + unit() * 0.50
            return SurfacePoint(x: 0.5 + (a.x + (b.x - a.x) * t - 0.5) * (1 - inward),
                                y: 0.5 + (a.y + (b.y - a.y) * t - 0.5) * (1 - inward))
        }
        sparkleSizes = (0..<sparkleCount).map { _ in 0.025 + unit() * 0.075 }
    }
}
