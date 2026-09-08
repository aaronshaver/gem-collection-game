import XCTest
@testable import GemCollectionGame

final class GemCollectionTests: XCTestCase {
    private func gem(_ id: Int, grade: Int = 1, shape: Int = 1, color: Int = 0) -> Gem {
        let c = PopulationConfiguration.standard
        return Gem(id: id, seed: UInt64(id), grade: c.grades[grade], color: c.colors[color], shape: c.shapes[shape])
    }

    func testCatalogHas72UniqueSetsAnd12PerColor() {
        let catalog = PopulationConfiguration.standard
        var all: Set<GemCombination> = []
        XCTAssertEqual(catalog.colors.count, 6)
        for color in catalog.colors {
            var section: Set<GemCombination> = []
            for shape in catalog.shapes {
                for grade in catalog.grades {
                    section.insert(GemCombination(Gem(id: 0, seed: 42, grade: grade, color: color, shape: shape)))
                }
            }
            XCTAssertEqual(section.count, 12)
            all.formUnion(section)
        }
        XCTAssertEqual(all.count, 72)
    }

    func testOnlyStrictSetsQualify() {
        for gems in [
            [gem(0), gem(1), gem(2, shape: 2)],
            [gem(0), gem(1, grade: 2), gem(2)],
            [gem(0), gem(1, color: 1), gem(2)],
            [gem(0), gem(1)]
        ] {
            var collection = GemCollection()
            collection.record(lines: [Array(gems.indices)], pieces: gems.map(BoardPiece.gem))
            XCTAssertTrue(collection.discovered.isEmpty)
            XCTAssertFalse(collection.hasUnread)
        }
        var collection = GemCollection()
        collection.record(lines: [[0, 1, 2]], pieces: (0..<3).map { .gem(gem($0)) })
        XCTAssertEqual(collection.discovered, [GemCombination(gem(0))])
        XCTAssertTrue(collection.hasUnread)
    }

    func testContiguousSubsetOfLongerColorMatchQualifiesButScatteredGemsDoNot() {
        var collection = GemCollection()
        let pieces = [gem(0), gem(1), gem(2, grade: 2), gem(3), gem(4)]
        collection.record(lines: [[0, 1, 2, 3, 4]], pieces: pieces.map(BoardPiece.gem))
        XCTAssertTrue(collection.discovered.isEmpty)
        collection.record(lines: [[0, 1, 2, 3, 4]], pieces: [gem(0, grade: 2), gem(1), gem(2), gem(3), gem(4)].map(BoardPiece.gem))
        XCTAssertEqual(collection.recent, [GemCombination(gem(1))])
    }

    func testVerticalSetAndOnlyResolvedLineQualify() {
        var pieces = (0..<15).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        for index in [0, 5, 10] { pieces[index] = .gem(gem(index)) }
        for index in [1, 2] { pieces[index] = .gem(gem(index, grade: 2)) }
        var collection = GemCollection()
        collection.record(lines: [[0, 1, 2]], pieces: pieces)
        XCTAssertTrue(collection.discovered.isEmpty)
        collection.record(lines: [[0, 5, 10]], pieces: pieces)
        XCTAssertEqual(collection.discovered, [GemCombination(gem(0))])
    }

    func testNewDiscoveriesKeepTwoMostRecentAndDuplicatesDoNotRestoreUnread() throws {
        var collection = GemCollection()
        let combinations = (0..<3).map { GemCombination(gem($0, color: $0)) }
        combinations.forEach { collection.record($0) }
        XCTAssertEqual(collection.recent, [combinations[2], combinations[1]])
        XCTAssertEqual(collection.discovered.count, 3)
        collection.markRead()
        collection.record(combinations[0])
        XCTAssertFalse(collection.hasUnread)
        XCTAssertEqual(collection.recent, [combinations[2], combinations[1]])
        XCTAssertEqual(try JSONDecoder().decode(GemCollection.self, from: JSONEncoder().encode(collection)), collection)
    }

    @MainActor
    func testBoardCommitsCollectionWithRewardAndPersistsReadState() async throws {
        let suite = "GemCollection.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = (0..<BoardLayout.cellCount).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        for index in [0, 1, 2] { pieces[index] = .gem(gem(index)) }
        defaults.set(try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard,
            pieces: pieces, pendingMatch: [0, 1, 2])), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertTrue(board.collection.discovered.isEmpty) // Older saves migrate safely.
        board.resolveIfNeeded()
        for _ in 0..<100 {
            if !board.isResolving { break }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertFalse(board.isResolving)
        XCTAssertTrue(board.collection.discovered.contains(GemCombination(gem(0))))
        XCTAssertGreaterThan(board.coins, 0)
        XCTAssertTrue(GameBoard(defaults: defaults).collection.hasUnread)
        board.markCollectionRead()
        let restored = GameBoard(defaults: defaults)
        XCTAssertEqual(restored.collection, board.collection)
        XCTAssertFalse(restored.collection.hasUnread)
        board.regenerate()
        XCTAssertEqual(board.collection, restored.collection)
    }
}
