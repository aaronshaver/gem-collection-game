import XCTest
@testable import FantasyTileMatcher

final class QuestProgressTests: XCTestCase {
    private struct SeededRandom: RandomNumberGenerator {
        var state: UInt64 = 42
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    func testRandomCompletionsAreAdditiveUniqueAndWithinRange() {
        var collection = QuestCollection(current: Adventurer.all[0])
        var random = SeededRandom()
        var previous = collection.completed
        for _ in 0..<4 {
            let added = collection.addRandomCompletions(using: &random)
            XCTAssertGreaterThanOrEqual(added, 168)
            XCTAssertLessThanOrEqual(added, 1008)
            XCTAssertEqual(collection.completed.count, previous.count + added)
            XCTAssertTrue(previous.isSubset(of: collection.completed))
            XCTAssertTrue(collection.hasUnread)
            if let current = collection.current { XCTAssertFalse(collection.completed.contains(current)) }
            previous = collection.completed
        }
    }

    func testRepeatedAdditionsStopAtAllCombinations() {
        var collection = QuestCollection()
        var random = SeededRandom()
        for _ in 0..<20 { collection.addRandomCompletions(using: &random) }
        XCTAssertEqual(collection.completed, Set(Adventurer.all))
        XCTAssertNil(collection.current)
        XCTAssertEqual(collection.addRandomCompletions(using: &random), 0)
        for attribute in Attribute.allCases {
            XCTAssertTrue(collection.progress(for: attribute).allSatisfy { $0.fraction == 1 })
        }
    }

    func testProgressOrderDenominatorsAndCounts() {
        var collection = QuestCollection()
        var random = SeededRandom()
        collection.addRandomCompletions(using: &random)
        XCTAssertEqual(Attribute.allCases.map(\.title), ["Races", "Classes", "Abilities", "Origins"])
        for (attribute, total, rowCount) in [(Attribute.race, 420, 8), (.adventurerClass, 336, 10), (.ability, 560, 6), (.origin, 480, 7)] {
            let rows = collection.progress(for: attribute)
            XCTAssertEqual(rows.count, rowCount)
            XCTAssertEqual(rows.map(\.name), attribute.names)
            XCTAssertEqual(rows.reduce(0) { $0 + $1.completed }, collection.completed.count)
            for row in rows {
                XCTAssertEqual(row.total, total)
                let expected = collection.completed.filter { attribute.value(in: $0) == row.name }.count
                XCTAssertEqual(row.completed, expected)
                XCTAssertEqual(row.fraction, Double(expected) / Double(total))
            }
        }
    }

    func testEmptyProgress() {
        let collection = QuestCollection()
        for attribute in Attribute.allCases {
            XCTAssertTrue(collection.progress(for: attribute).allSatisfy { $0.completed == 0 && $0.fraction == 0 })
        }
    }

    @MainActor
    func testDevAdditionPersistsAndDoesNotChangeGoldOrBoard() throws {
        let suite = "QuestProgressTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let board = GameBoard(defaults: defaults)
        let pieces = board.pieces
        board.addRandomCompletion()
        XCTAssertTrue((168...1008).contains(board.collection.completed.count))
        XCTAssertEqual(board.gold, 0)
        XCTAssertEqual(board.pieces, pieces)
        XCTAssertEqual(board.discoveryEvent, 0)
        let reloaded = GameBoard(defaults: defaults)
        XCTAssertEqual(reloaded.collection, board.collection)
        board.addRandomCompletion()
        XCTAssertTrue(reloaded.collection.completed.isSubset(of: board.collection.completed))
    }
}
