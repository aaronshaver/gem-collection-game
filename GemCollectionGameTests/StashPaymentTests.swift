import XCTest
@testable import GemCollectionGame

final class StashPaymentTests: XCTestCase {
    @MainActor
    func testReservationCancellationAndRelaunchRefundExactlyOnce() throws {
        let suite = "StashPayment.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let c = PopulationConfiguration.standard
        var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        pieces[0] = .gem(Gem(id: 0, seed: 0, grade: c.grades[1], color: c.colors[0], shape: c.shapes[0]))
        defaults.set(try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: c, pieces: pieces, coins: 10)),
                     forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertFalse(board.stashGem(at: 0))
        XCTAssertFalse(board.beginStashAction(.placing))
        XCTAssertTrue(board.beginStashAction(.storing))
        XCTAssertEqual(board.coins, 5)
        XCTAssertFalse(board.beginStashAction(.storing))
        XCTAssertFalse(board.stashGem(at: 1))
        XCTAssertEqual(board.coins, 5)
        board.cancelStashAction()
        board.cancelStashAction()
        XCTAssertEqual(board.coins, 10)
        XCTAssertEqual(board.pieces, pieces)
        XCTAssertTrue(board.beginStashAction(.storing))
        let restored = GameBoard(defaults: defaults)
        XCTAssertEqual(restored.coins, 10)
        XCTAssertNil(restored.pendingStashAction)
        XCTAssertEqual(GameBoard(defaults: defaults).coins, 10)
        XCTAssertTrue(restored.beginStashAction(.storing))
        XCTAssertTrue(restored.stashGem(at: 0))
        restored.cancelStashAction()
        XCTAssertEqual(restored.coins, 5)
        XCTAssertTrue(restored.beginStashAction(.placing))
        XCTAssertEqual(restored.coins, 0)
        XCTAssertFalse(restored.placeStashedGem(from: 2, at: 1))
        restored.cancelStashAction()
        XCTAssertEqual(restored.coins, 5)
        XCTAssertNotNil(restored.stash.slots[0])
        XCTAssertTrue(restored.beginStashAction(.placing))
        XCTAssertTrue(restored.placeStashedGem(from: 0, at: 1))
        restored.cancelStashAction()
        XCTAssertEqual(restored.coins, 0)
        XCTAssertEqual(GameBoard(defaults: defaults).coins, 0)
        restored.regenerate()
        XCTAssertFalse(restored.beginStashAction(.storing))
        XCTAssertEqual(restored.coins, 0)
    }
}
