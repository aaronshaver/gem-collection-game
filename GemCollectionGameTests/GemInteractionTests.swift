import XCTest
@testable import GemCollectionGame

final class GemInteractionTests: XCTestCase {
    func testRejectedPairingsInBothDirections() {
        let catalog = PopulationConfiguration.standard
        func gem(_ color: Int) -> BoardPiece {
            .gem(Gem(id: color, seed: 1, grade: catalog.grades[0], color: catalog.colors[color], shape: catalog.shapes[0]))
        }
        let rock = BoardPiece.rock(Rock(id: 99, seed: 1))
        XCTAssertTrue(SwapRules.rejects(rock, rock))
        XCTAssertTrue(SwapRules.rejects(rock, gem(0)))
        XCTAssertTrue(SwapRules.rejects(gem(0), rock))
        XCTAssertTrue(SwapRules.rejects(gem(0), gem(1)))
        XCTAssertTrue(SwapRules.rejects(gem(1), gem(0)))
        XCTAssertFalse(SwapRules.rejects(gem(0), gem(0)))
    }

    func testCracksStayInsideEveryShapeAndVaryAcrossSeeds() {
        let catalog = PopulationConfiguration.standard
        var counts = Set<Int>()
        for shape in catalog.shapes {
            for seed in 0..<100 {
                let gem = Gem(id: 0, seed: UInt64(seed), grade: catalog.grades[0], color: catalog.colors[0], shape: shape)
                counts.insert(gem.crackPaths.count)
                let vertices = (0..<shape.sides).map { index -> SurfacePoint in
                    let angle = gem.rotation + Double(index) * .pi * 2 / Double(shape.sides)
                    return SurfacePoint(x: 0.5 + cos(angle) * 0.46, y: 0.5 + sin(angle) * 0.46)
                }
                for p in gem.crackPaths.flatMap({ $0 }) {
                    for i in vertices.indices {
                        let a = vertices[i], b = vertices[(i + 1) % vertices.count]
                        let cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
                        XCTAssertGreaterThanOrEqual(cross, -0.000001)
                    }
                }
            }
        }
        XCTAssertGreaterThan(counts.count, 2)
    }
}
