import XCTest
@testable import FantasyTileMatcher

final class PopulationTests: XCTestCase {
    func testCatalogAndSeededUniformPopulation() {
        XCTAssertEqual(Race.allCases.count, 8)
        XCTAssertEqual(Adventurer.all.count, 3360)
        XCTAssertEqual(Set(Adventurer.all).count, 3360)
        let generator = PopulationGenerator()
        let pieces = generator.generate(seed: 42, count: 50000, startingID: 100)
        XCTAssertEqual(pieces, generator.generate(seed: 42, count: 50000, startingID: 100))
        XCTAssertEqual(Set(pieces.map(\.id)).count, 50000)
        for attribute in 0..<4 {
            let counts = Dictionary(grouping: pieces, by: { $0.adventurer.values[attribute] }).mapValues(\.count)
            let expected = Double(pieces.count) / Double(counts.count)
            for count in counts.values { XCTAssertEqual(Double(count) / expected, 1, accuracy: 0.07) }
        }
    }

    func testFreshBoardsPreserveUnfilteredRandomDrawsIncludingStartingMatches() {
        let generator = PopulationGenerator()
        var boardsWithMatches = 0
        for seed in 0..<1000 {
            let pieces = generator.freshField(seed: UInt64(seed), startingID: 100)
            XCTAssertEqual(pieces.count, 15)
            XCTAssertEqual(pieces, generator.generate(seed: UInt64(seed), count: 15, startingID: 100))
            if MatchRules.hasMatch(in: pieces) { boardsWithMatches += 1 }
        }
        XCTAssertGreaterThan(boardsWithMatches, 0)
    }

    func testMatchScanPerformance() {
        let pieces = PopulationGenerator().generate(seed: 41, count: 15)
        measure {
            for _ in 0..<100 {
                _ = MatchResolution.scan(pieces)
            }
        }
    }
}
