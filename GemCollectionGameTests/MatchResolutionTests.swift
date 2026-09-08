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

    func testCrossCollectsOnlyOneStraightLine() {
        var pieces = field()
        for index in [5, 6, 7, 1, 11] { pieces[index] = gem(index) }
        let batch = MatchResolution.scan(pieces)
        XCTAssertEqual(batch.lines, [[1, 6, 11]])
        XCTAssertEqual(batch.coins, 3)
    }


    func testGestureAxisWinsEvenWhenOtherArmIsLonger() {
        var pieces = field()
        for index in [5, 6, 7, 8, 9, 1, 11] { pieces[index] = gem(index) }
        XCTAssertEqual(MatchResolution.scan(pieces, swapping: (7, 6)).lines, [[1, 6, 11]])
        XCTAssertEqual(MatchResolution.scan(pieces, swapping: (11, 6)).lines, [[5, 6, 7, 8, 9]])
    }

    func testDestinationLineWinsEvenWhenDisplacedPieceMakesLongerLine() {
        var pieces = field()
        for index in [0, 5, 10, 1, 6, 11, 16] { pieces[index] = gem(index) }
        XCTAssertEqual(MatchResolution.scan(pieces, swapping: (5, 6)).lines, [[1, 6, 11, 16]])
        XCTAssertEqual(MatchResolution.scan(pieces, swapping: (6, 5)).lines, [[0, 5, 10]])
    }

    func testGravityDoesNotActivateAnExistingUnselectedLine() {
        var pieces = field()
        for index in [0, 1, 2, 20, 21, 22] { pieces[index] = gem(index) }
        XCTAssertTrue(MatchResolution.scan(pieces, formedAfter: pieces).lines.isEmpty)
        var after = pieces
        after.swapAt(20, 25)
        after.swapAt(21, 26)
        after.swapAt(22, 27)
        XCTAssertTrue(MatchResolution.scan(after, formedAfter: pieces).lines.isEmpty)
    }

    func testGravityCanFormANewLineButNeverCollectsItsWholeIntersection() {
        var before = field()
        for index in [0, 6, 12, 1, 11] { before[index] = gem(index) }
        var after = before
        after.swapAt(0, 5)
        after.swapAt(12, 7)
        let batch = MatchResolution.scan(after, formedAfter: before)
        XCTAssertEqual(batch.lines, [[5, 6, 7]])
        XCTAssertEqual(batch.indices.count, 3)
    }

    @MainActor
    func testSavedIntentSurvivesReloadAtIntersection() async throws {
        let suite = "SavedIntent.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = field()
        for index in [1, 5, 6, 7, 11] { pieces[index] = gem(index) }
        let save = GameBoard.Save(seed: 1, configuration: .standard, pieces: pieces, pendingMatch: [5, 6, 7])
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        board.resolveIfNeeded()
        for _ in 0..<50 {
            if !board.collectedIDs.isEmpty { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(board.collectedIDs, [5, 6, 7])
        board.regenerate()
    }

    @MainActor
    func testDraggedOrangeLineCollectsBeforeUpperDisplacedRedLine() async throws {
        let catalog = PopulationConfiguration.standard
        for (source, target, expected) in [(6, 11, Set([10, 6, 12])), (11, 6, Set([5, 11, 7]))] {
            let suite = "DestinationFirst.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            var pieces = field()
            for index in [5, 7, 11] { pieces[index] = gem(index) }
            for index in [6, 10, 12] {
                pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: catalog.grades[0],
                    color: catalog.colors[1], shape: catalog.shapes[0]))
            }
            XCTAssertFalse(MatchRules.hasMatch(in: pieces))
            defaults.set(try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard,
                pieces: pieces)), forKey: GameBoard.storageKey)
            let board = GameBoard(defaults: defaults)
            XCTAssertTrue(board.swap(source, target))
            let saved = try JSONDecoder().decode(GameBoard.Save.self,
                from: XCTUnwrap(defaults.data(forKey: GameBoard.storageKey)))
            XCTAssertEqual(saved.pendingMatch, target == 11 ? [10, 11, 12] : [5, 6, 7])
            for _ in 0..<50 {
                if !board.collectedIDs.isEmpty { break }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            XCTAssertEqual(board.collectedIDs, expected)
            // The opposite line still exists until the first collection's animation completes.
            XCTAssertEqual(board.pieces.count, pieces.count)
            XCTAssertEqual(board.coins, 0)
            board.regenerate()
        }
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
