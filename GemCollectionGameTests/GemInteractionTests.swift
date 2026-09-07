import XCTest
@testable import GemCollectionGame

final class GemInteractionTests: XCTestCase {
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
