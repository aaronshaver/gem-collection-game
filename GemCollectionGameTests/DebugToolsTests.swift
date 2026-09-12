import XCTest
@testable import GemCollectionGame

#if DEBUG
final class DebugToolsTests: XCTestCase {
    @MainActor
    func testFakeDiscoveryReplaysCelebrationWithoutChangingTheGame() async throws {
        let suite = "DebugPreview.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let board = GameBoard(defaults: defaults)
        let pieces = board.pieces
        let collection = board.collection
        let stash = board.stash
        let coins = board.coins
        let saved = defaults.data(forKey: GameBoard.storageKey)

        board.previewDiscovery()
        XCTAssertEqual(board.discoveryEvent, 1)
        board.previewDiscovery()
        XCTAssertEqual(board.discoveryEvent, 2)
        XCTAssertEqual(board.pieces, pieces)
        XCTAssertEqual(board.collection, collection)
        XCTAssertEqual(board.stash, stash)
        XCTAssertEqual(board.coins, coins)
        XCTAssertFalse(board.isResolving)
        XCTAssertEqual(defaults.data(forKey: GameBoard.storageKey), saved)
    }
}
#endif
