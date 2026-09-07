import XCTest
@testable import GemCollectionGame

final class MatchRewardTests: XCTestCase {
    private func gems(grades: [Int], shapes: [Int]) -> [BoardPiece] {
        let c = PopulationConfiguration.standard
        return grades.indices.map { .gem(Gem(id: $0, seed: UInt64($0), grade: c.grades[grades[$0]], color: c.colors[3], shape: c.shapes[shapes[$0]])) }
    }

    func testAllFourRewardTiersAndBannerLabels() {
        let examples: [([Int], [Int], Int, String)] = [
            ([0, 1, 2], [0, 1, 2], 3, "3 Green matched"),
            ([1, 1, 1], [0, 1, 2], 12, "3 Green Dull matched"),
            ([0, 1, 2], [2, 2, 2], 15, "3 Green 5-sided matched"),
            ([2, 2, 2, 2, 2], [2, 2, 2, 2, 2], 40, "5 Green Shiny 5-sided matched")
        ]
        for (grades, shapes, coins, label) in examples {
            let batch = MatchResolution.scan(gems(grades: grades, shapes: shapes))
            XCTAssertEqual(batch.coins, coins)
            XCTAssertEqual(batch.rewards.first?.banner, label)
        }
    }

    func testPartialClassAndShapeDoNotEarnBonus() {
        let batch = MatchResolution.scan(gems(grades: [1, 1, 1, 1, 2], shapes: [2, 2, 2, 2, 3]))
        XCTAssertEqual(batch.coins, 5)
        XCTAssertEqual(batch.rewards.first?.banner, "5 Green matched")
    }

    func testIntersectingClassAndShapeBonusesNeverCombineIntoEight() {
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
            let batch = MatchResolution.scan(pieces)
            XCTAssertEqual(batch.lines.count, 2)
            XCTAssertEqual(Set(batch.rewards.map(\.coinsPerGem)), [4, 5])
            XCTAssertEqual(batch.coins, 23) // Three at 5, plus two at 4. Shared gem gets 5, not 8.
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

    func testIntersectionUsesHighestRateForSharedGemOnce() {
        var pieces = (0..<15).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        let c = PopulationConfiguration.standard
        for index in [1, 5, 6, 7, 11] {
            let vertical = [1, 6, 11].contains(index)
            pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: c.grades[vertical ? 2 : 0], color: c.colors[0], shape: c.shapes[2]))
        }
        // Vertical: 3 * 8. Horizontal-only endpoints: 2 * 5. Center isn't paid twice.
        XCTAssertEqual(MatchResolution.scan(pieces).coins, 34)
    }
}
