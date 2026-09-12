import XCTest
import SwiftUI
@testable import FantasyTileMatcher

@MainActor
final class GameBoardTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    override func setUp() async throws {
        suite = "FantasyTests.\(UUID())"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() async throws { defaults.removePersistentDomain(forName: suite) }

    func testNonmatchingSwapPersistenceAndRefreshPreserveProgress() throws {
        let board = GameBoard(defaults: defaults)
        let original = board.pieces
        let pair = try XCTUnwrap((0..<15).flatMap { source in
            [source + 1, source + 3].compactMap { target -> (Int, Int)? in
                guard SwapRules.canSwap(source, target, in: board.pieces) else { return nil }
                var swapped = board.pieces
                swapped.swapAt(source, target)
                return MatchRules.hasMatch(in: swapped) ? nil : (source, target)
            }
        }.first)
        XCTAssertTrue(board.swap(pair.0, pair.1))
        XCTAssertEqual(board.pieces[pair.1], original[pair.0])
        XCTAssertFalse(board.isResolving)
        let reloaded = GameBoard(defaults: defaults)
        XCTAssertEqual(reloaded.pieces, board.pieces)
        XCTAssertEqual(reloaded.collection, board.collection)
        let before = board.pieces
        board.regenerate()
        XCTAssertNotEqual(board.pieces, before)
        XCTAssertEqual(board.collection, reloaded.collection)
    }

    func testOnlyCurrentExactTargetCompletesQuestOnce() {
        let target = Adventurer.all[0]
        var collection = QuestCollection(current: target)
        let other = (0..<3).map { Tile(id: $0, adventurer: Adventurer.all[1]) }
        XCTAssertFalse(collection.record(lines: [[0, 1, 2]], pieces: other))
        XCTAssertEqual(collection.current, target)
        let exact = (0..<3).map { Tile(id: $0, adventurer: target) }
        XCTAssertTrue(collection.record(lines: [[0, 1, 2], [0, 1, 2]], pieces: exact))
        XCTAssertEqual(collection.completed, [target])
        XCTAssertNotEqual(collection.current, target)
        XCTAssertTrue(collection.hasUnread)
        XCTAssertFalse(collection.record(lines: [[0, 1, 2]], pieces: exact))
        collection.markRead()
        XCTAssertFalse(collection.hasUnread)
    }

    func testPartialMatchesNeverCompleteCurrentQuest() {
        let target = Adventurer.all[0]
        var collection = QuestCollection(current: target)
        let pieces = [target, target, Adventurer.all[1]].enumerated().map { Tile(id: $0.offset, adventurer: $0.element) }
        XCTAssertFalse(collection.record(lines: [[0, 1, 2]], pieces: pieces))
        XCTAssertTrue(collection.completed.isEmpty)
    }

    func testPendingMatchResumesAndCommitsRewardAndQuestTogether() async throws {
        var pieces = PopulationGenerator().freshField(seed: 42)
        let target = Adventurer.all[0]
        for id in 0..<3 { pieces[id] = Tile(id: id, adventurer: target) }
        let save = GameBoard.Save(pieces: pieces, gold: 0, collection: QuestCollection(current: target))
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        board.resolveIfNeeded()
        XCTAssertTrue(board.isResolving)
        XCTAssertFalse(board.swap(0, 1))
        for _ in 0..<150 {
            if board.discoveryEvent > 0 { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(board.discoveryEvent, 1)
        XCTAssertGreaterThanOrEqual(board.gold, 24)
        XCTAssertTrue(board.collection.completed.contains(target))
        let reloaded = GameBoard(defaults: defaults)
        XCTAssertEqual(reloaded.gold, board.gold)
        XCTAssertEqual(reloaded.collection, board.collection)
        XCTAssertEqual(reloaded.discoveryEvent, 0)
        board.resetAll()
        let resetPieces = board.pieces
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertEqual(board.pieces, resetPieces)
        XCTAssertEqual(board.gold, 0)
        XCTAssertTrue(board.collection.completed.isEmpty)
        XCTAssertFalse(board.collection.hasUnread)
        XCTAssertNotNil(board.collection.current)
        XCTAssertFalse(board.isResolving)
        XCTAssertTrue(board.spawnRows.isEmpty)
        XCTAssertTrue(board.collectedIDs.isEmpty)
        XCTAssertEqual(GameBoard(defaults: defaults).pieces, resetPieces)
    }

    func testResetCancelsBeforeRewardIsApplied() async throws {
        var pieces = PopulationGenerator().freshField(seed: 42)
        let target = Adventurer.all[0]
        for id in 0..<3 { pieces[id] = Tile(id: id, adventurer: target) }
        defaults.set(try JSONEncoder().encode(GameBoard.Save(pieces: pieces, gold: 99,
                     collection: QuestCollection(current: target))), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        board.resolveIfNeeded()
        board.resetAll()
        let resetPieces = board.pieces
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(board.gold, 0)
        XCTAssertEqual(board.pieces, resetPieces)
        XCTAssertTrue(board.collection.completed.isEmpty)
    }

    func testLaunchDeletesObsoleteSavesAndPreservesCurrentProgress() {
        let original = GameBoard(defaults: defaults)
        defaults.set(Data("obsolete board and stash".utf8), forKey: "gameBoard.population.v1")
        defaults.set(Data("obsolete appearances".utf8), forKey: "rockBoard.appearances.v1")
        let reloaded = GameBoard(defaults: defaults)
        XCTAssertNil(defaults.object(forKey: "gameBoard.population.v1"))
        XCTAssertNil(defaults.object(forKey: "rockBoard.appearances.v1"))
        XCTAssertEqual(reloaded.pieces, original.pieces)
        XCTAssertEqual(reloaded.collection, original.collection)
    }

    func testMissingBoardDataPreservesGoldAndQuestProgress() throws {
        let collection = QuestCollection(current: Adventurer.all[0])
        let save = GameBoard.Save(pieces: nil, gold: 123, collection: collection)
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertEqual(board.gold, 123)
        XCTAssertEqual(board.collection, collection)
        XCTAssertEqual(board.pieces.count, 15)
        XCTAssertFalse(MatchRules.hasMatch(in: board.pieces))
        XCTAssertEqual(GameBoard(defaults: defaults).pieces, board.pieces)
    }

    func testMalformedSaveFallsBackToNewGame() throws {
        defaults.set(Data("{}".utf8), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertEqual(board.pieces.count, 15)
        XCTAssertEqual(board.gold, 0)
    }

    func testReducedMotionShakeIsAlwaysIdentity() {
        for progress in stride(from: 0.0, through: 2, by: 0.025) {
            XCTAssertTrue(DiscoveryShake(progress: progress, enabled: false).effectValue(size: CGSize(width: 390, height: 680)).isIdentity)
        }
        XCTAssertTrue(DiscoveryShake(progress: 1).effectValue(size: .zero).isIdentity)
    }
}
