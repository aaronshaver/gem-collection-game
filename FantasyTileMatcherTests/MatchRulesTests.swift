import XCTest
@testable import FantasyTileMatcher

final class MatchRulesTests: XCTestCase {
    private func tile(_ id: Int, _ values: [Int]) -> Tile {
        Tile(id: id, adventurer: Adventurer(race: Race.allCases[values[0]],
            adventurerClass: AdventurerClass.allCases[values[1]], ability: Ability.allCases[values[2]],
            origin: Origin.allCases[values[3]]))
    }

    func testSingleAttributeNeverMatchesInEitherDirection() {
        for attribute in 0..<4 {
            let pieces = (0..<3).map { id -> Tile in
                var values = [id, id, id, id]
                values[attribute] = 0
                return tile(id, values)
            }
            for columns in [1, 3] {
                let result = MatchResolution.scan(pieces, columns: columns)
                XCTAssertTrue(result.indices.isEmpty)
                XCTAssertEqual(result.gold, 0)
            }
        }
    }

    func testEveryPairOfAttributesQualifiesInBothDirections() {
        for first in 0..<4 {
            for second in (first + 1)..<4 {
                let pieces = (0..<3).map { id -> Tile in
                    var values = [id, id, id, id]
                    values[first] = 0
                    values[second] = 0
                    return tile(id, values)
                }
                for columns in [1, 3] {
                    let result = MatchResolution.scan(pieces, columns: columns)
                    XCTAssertEqual(result.indices, [0, 1, 2])
                    XCTAssertEqual(result.gold, 6)
                }
            }
        }
    }

    func testDifferentPairsBetweenNeighborsDoNotMakeAMatch() {
        let pieces = [tile(0, [0, 0, 1, 1]), tile(1, [0, 0, 0, 0]), tile(2, [1, 1, 0, 0])]
        XCTAssertFalse(MatchRules.hasMatch(in: pieces))
    }

    func testTwoThreeFourSharedAttributesPayTwoFourEightPerTile() {
        for shared in 2...4 {
            let pieces = (0..<3).map { id in tile(id, (0..<4).map { $0 < shared ? 0 : id }) }
            XCTAssertEqual(MatchResolution.scan(pieces).gold, 3 * (1 << (shared - 1)))
        }
    }

    func testLinesOfFourAndFiveAndExactSubrunGetFullReward() {
        for count in [4, 5] {
            let exact = tile(0, [0, 0, 0, 0]).adventurer
            let pieces = (0..<count).map { id in
                id < 3 ? Tile(id: id, adventurer: exact) : tile(id, [0, 0, id, id])
            }
            let result = MatchResolution.scan(pieces, columns: 1)
            XCTAssertEqual(result.indices.count, count)
            XCTAssertEqual(result.gold, 24 + 2 * (count - 3))
        }
    }

    func testIntersectionPaysEachTileOnceAtItsStrongestRate() {
        var pieces = (0..<9).map { tile($0, [$0 % 8, $0, $0 % 6, $0 % 7]) }
        for id in [3, 4, 5] { pieces[id] = tile(id, [0, 0, 0, 0]) }
        for id in [1, 7] { pieces[id] = tile(id, [0, 0, id % 6, id % 7]) }
        pieces[6] = tile(6, [6, 6, 5, 6])
        let result = MatchResolution.scan(pieces)
        XCTAssertEqual(result.indices, [1, 3, 4, 5, 7])
        XCTAssertEqual(result.gold, 28)
    }

    func testNoDiagonalOrWrappedOrTwoTileMatches() {
        var pieces = (0..<9).map { tile($0, [$0 % 8, $0, $0 % 6, $0 % 7]) }
        for id in [0, 4, 8] { pieces[id] = tile(id, [0, 0, 0, 0]) }
        XCTAssertFalse(MatchRules.hasMatch(in: pieces))
        for id in [0, 4, 8] { pieces[id] = tile(id, [id % 8, id, id % 6, id % 7]) }
        pieces[6] = tile(6, [6, 6, 5, 6])
        for id in [2, 3, 4] { pieces[id] = tile(id, [0, 0, 0, 0]) }
        XCTAssertFalse(MatchRules.hasMatch(in: pieces))
        XCTAssertFalse(MatchRules.hasMatch(in: Array(pieces.prefix(2))))
    }

    func testAdjacentSwapsDoNotRequireMatchOrDifferentAttributes() {
        let pieces = (0..<15).map { tile($0, [0, 0, 0, 0]) }
        for target in [1, 3] { XCTAssertTrue(SwapRules.canSwap(0, target, in: pieces)) }
        for target in [-1, 0, 2, 4, 15] { XCTAssertFalse(SwapRules.canSwap(0, target, in: pieces)) }
        XCTAssertFalse(SwapRules.canSwap(2, 3, in: pieces))
        XCTAssertFalse(SwapRules.canSwap(0, 1, in: pieces, columns: 0))
    }

    func testCollapseKeepsSurvivorOrderAndAssignsSpawnRows() {
        let pieces = (0..<15).map { tile($0, [0, 0, 0, 0]) }
        let incoming = (15..<18).map { tile($0, [1, 1, 1, 1]) }
        let result = MatchResolution.collapse(pieces, removing: [3, 6, 10], replacements: incoming)
        XCTAssertEqual(stride(from: 0, to: 15, by: 3).map { result.pieces[$0].id }, [15, 16, 0, 9, 12])
        XCTAssertEqual(stride(from: 1, to: 15, by: 3).map { result.pieces[$0].id }, [17, 1, 4, 7, 13])
        XCTAssertEqual(result.spawnRows, [15: -2, 16: -1, 17: -1])
        XCTAssertEqual(Set(result.pieces.map(\.id)).count, 15)
    }
}
