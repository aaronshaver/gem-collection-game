import XCTest
@testable import GemCollectionGame

final class GemVariationTests: XCTestCase {
    func testStoredShinyVariationCoversCountsSizesAndFullRotation() throws {
        let catalog = PopulationConfiguration.standard
        var counts = Set<Int>()
        var quadrants = Set<Int>()
        for seed in 0..<200 {
            let gem = Gem(id: seed, seed: UInt64(seed), grade: catalog.grades[2], color: catalog.colors[0], shape: catalog.shapes[0])
            XCTAssertTrue((3...6).contains(gem.sparkles.count))
            counts.insert(gem.sparkles.count)
            quadrants.insert(Int(gem.rotation / (.pi / 2)))
            let sizes = try XCTUnwrap(gem.sparkleSizes)
            XCTAssertEqual(sizes.count, gem.sparkles.count)
            XCTAssertTrue(sizes.allSatisfy { (0.025...0.10).contains($0) })
            XCTAssertGreaterThan(Set(sizes).count, 1)
            XCTAssertEqual(gem, try JSONDecoder().decode(Gem.self, from: JSONEncoder().encode(gem)))
        }
        XCTAssertEqual(counts, Set(3...6))
        XCTAssertEqual(quadrants, Set(0...3))
    }
}
