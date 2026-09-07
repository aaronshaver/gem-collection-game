import XCTest
@testable import GemCollectionGame

final class MatchResolutionTests: XCTestCase {
    private func field() -> [BoardPiece] {
        (0..<45).map { .rock(Rock(id: $0, seed: UInt64($0))) }
    }
    private func gem(_ id: Int) -> BoardPiece {
        let catalog = PopulationConfiguration.standard
        return .gem(Gem(id: id, seed: UInt64(id), grade: catalog.grades[id % 3],
                        color: catalog.colors[0], shape: catalog.shapes[id % 4]))
    }

    func testLongLinesAwardOneCoinPerGem() {
        var pieces = field()
        for index in 0..<5 { pieces[index] = gem(index) }
        let batch = MatchResolution.scan(pieces)
        XCTAssertEqual(batch.lines.count, 1)
        XCTAssertEqual(batch.coins, 5)
        XCTAssertEqual(batch.indices, Set(0..<5))
    }

    func testCrossAwardsSharedGemOnlyOnce() {
        var pieces = field()
        for index in [5, 6, 7, 1, 11] { pieces[index] = gem(index) }
        let batch = MatchResolution.scan(pieces)
        XCTAssertEqual(batch.lines.count, 2)
        XCTAssertEqual(batch.coins, 5)
    }

    func testGravityPreservesColumnOrderAndRefillsOnlyVacancies() {
        let pieces = field()
        let removed: Set<Int> = [10, 20, 40, 44]
        let replacements = (100..<104).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        let result = MatchResolution.collapse(pieces, removing: removed, replacements: replacements)
        XCTAssertEqual(result.pieces.count, 45)
        XCTAssertEqual(Set(result.pieces.map(\.id)).count, 45)
        XCTAssertEqual(stride(from: 0, to: 45, by: 5).map { result.pieces[$0].id }, [100, 101, 102, 0, 5, 15, 25, 30, 35])
        XCTAssertEqual(result.pieces[4].id, 103)
        XCTAssertEqual(result.pieces[44].id, 39)
        XCTAssertEqual(result.spawnRows[100], -3)
        XCTAssertEqual(result.spawnRows[102], -1)
        XCTAssertEqual(result.pieces[1], pieces[1])
    }

    @MainActor
    func testResolutionAwardsPersistsRefillsAndUnlocks() async throws {
        let suite = "CollectionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = field()
        for index in [0, 1, 7] { pieces[index] = gem(index) }
        let save = GameBoard.Save(seed: 1, configuration: .standard, pieces: pieces)
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertTrue(board.swap(2, 7))
        XCTAssertTrue(board.isResolving)
        XCTAssertFalse(board.swap(2, 7))
        for _ in 0..<200 {
            if !board.isResolving { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(board.isResolving)
        XCTAssertGreaterThanOrEqual(board.coins, 3)
        XCTAssertTrue(Set([0, 1, 7]).isDisjoint(with: board.pieces.map(\.id)))
        XCTAssertEqual(board.pieces.count, 45)
        XCTAssertFalse(MatchRules.hasMatch(in: board.pieces))
        let restored = GameBoard(defaults: defaults)
        XCTAssertEqual(board.pieces, restored.pieces)
        XCTAssertEqual(board.coins, restored.coins)
    }

    @MainActor
    func testRegenerationCancelsPendingCollection() async throws {
        let suite = "CancelCollectionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = field()
        for index in [0, 1, 2] { pieces[index] = gem(index) }
        defaults.set(try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard, pieces: pieces)), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        board.resolveIfNeeded()
        board.regenerate()
        let fresh = board.pieces
        try await Task.sleep(nanoseconds: 800_000_000)
        XCTAssertEqual(board.pieces, fresh)
        XCTAssertEqual(board.coins, 0)
        XCTAssertFalse(board.isResolving)
    }
}
