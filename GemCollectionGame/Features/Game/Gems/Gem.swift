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

    init(id: Int, seed: UInt64, grade: GemGrade, color: GemColor, shape: GemShape) {
        self.id = id
        self.seed = seed
        self.grade = grade
        self.color = color
        self.shape = shape
        generationVersion = 2
        let random = GKLinearCongruentialRandomSource(seed: seed)
        func unit() -> Double { Double(random.nextUniform()) }
        let orientation = -Double.pi / 2 + (unit() - 0.5) * 0.24
        rotation = orientation
        crackPaths = GemCracks.generate(sides: shape.sides, rotation: orientation,
                                         maximumFractures: grade.crackCount, random: random)
        sparkles = (0..<grade.sparkleCount).map { index in
            let angle = orientation + Double(index) * .pi * 2 / Double(max(grade.sparkleCount, 1))
            return SurfacePoint(x: 0.5 + cos(angle) * 0.33, y: 0.5 + sin(angle) * 0.33)
        }
    }
}
