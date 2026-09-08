import XCTest
@testable import GemCollectionGame

final class MatchRewardTests: XCTestCase {
    private func gems(grades: [Int], shapes: [Int]) -> [BoardPiece] {
        let c = PopulationConfiguration.standard
        return grades.indices.map { .gem(Gem(id: $0, seed: UInt64($0), grade: c.grades[grades[$0]], color: c.colors[3], shape: c.shapes[shapes[$0]])) }
    }

    func testAllFourRewardTiers() {
        let examples: [([Int], [Int], Int)] = [
            ([0, 1, 2], [0, 1, 2], 3),
            ([1, 1, 1], [0, 1, 2], 12),
            ([0, 1, 2], [2, 2, 2], 15),
            ([2, 2, 2, 2, 2], [2, 2, 2, 2, 2], 40)
        ]
        for (grades, shapes, coins) in examples {
            XCTAssertEqual(MatchResolution.scan(gems(grades: grades, shapes: shapes)).coins, coins)
        }
    }

    func testPartialClassAndShapeDoNotEarnBonus() {
        let batch = MatchResolution.scan(gems(grades: [1, 1, 1, 1, 2], shapes: [2, 2, 2, 2, 3]))
        XCTAssertEqual(batch.coins, 5)
    }

    func testOnlyIntendedLineEarnsRewardsAtIntersections() {
        let c = PopulationConfiguration.standard
        // A cross, a T, and an L; each has two qualifying three-gem lines.
        for (horizontal, vertical) in [([5, 6, 7], [1, 6, 11]),
                                        ([0, 1, 2], [1, 6, 11]),
                                        ([0, 1, 2], [0, 5, 10])] {
            var pieces = (0..<15).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
            let shared = Set(horizontal).intersection(vertical).first!
            for index in vertical {
                let shape = index == shared ? 2 : (index % 2 == 0 ? 0 : 3)
                pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: c.grades[1], color: c.colors[0], shape: c.shapes[shape]))
            }
            for index in horizontal {
                let grade = index == shared ? 1 : 0
                pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: c.grades[grade], color: c.colors[0], shape: c.shapes[2]))
            }
            let horizontalBatch = MatchResolution.scan(pieces, swapping: (shared + 5, shared))
            XCTAssertEqual(horizontalBatch.lines, [horizontal])
            XCTAssertEqual(horizontalBatch.coins, 15)
            let verticalBatch = MatchResolution.scan(pieces, swapping: (shared + 1, shared))
            XCTAssertEqual(verticalBatch.lines, [vertical])
            XCTAssertEqual(verticalBatch.coins, 12)
        }
    }

    func testTwoGemArmDoesNotQualifyOrGetCollected() {
        let c = PopulationConfiguration.standard
        var pieces = (0..<15).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        for index in [1, 5, 6, 7] {
            pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: c.grades[index == 1 || index == 6 ? 1 : 0],
                                    color: c.colors[0], shape: c.shapes[index == 1 ? 0 : 2]))
        }
        let batch = MatchResolution.scan(pieces)
        XCTAssertEqual(batch.lines, [[5, 6, 7]])
        XCTAssertEqual(batch.indices, [5, 6, 7])
        XCTAssertEqual(batch.coins, 15)
    }

}
