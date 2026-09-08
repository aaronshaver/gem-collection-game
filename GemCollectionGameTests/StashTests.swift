import XCTest

@testable import GemCollectionGame

final class StashTests: XCTestCase {
    private func gem(_ id: Int) -> Gem {
        let catalog = PopulationConfiguration.standard
        return Gem(
            id: id, seed: UInt64(id), grade: catalog.grades[0],
            color: catalog.colors[0], shape: catalog.shapes[0])
    }

    func testFirstFreeSlotAndDuplicateCombinations() {
        var stash = GemStash(capacity: 3)
        XCTAssertTrue(stash.insert(gem(100)))
        XCTAssertTrue(stash.insert(gem(101)))
        XCTAssertEqual(stash.slots[0], gem(100))
        XCTAssertEqual(stash.slots[1], gem(101))
        stash.remove(at: 0)
        XCTAssertTrue(stash.insert(gem(102)))
        XCTAssertEqual(stash.slots[0], gem(102))
        XCTAssertEqual(stash.slots[1], gem(101))
        XCTAssertTrue(stash.insert(gem(103)))
        XCTAssertFalse(stash.insert(gem(104)))
    }

    @MainActor
    func testTransferPersistenceCapacityRocksAndPlacement() async throws {
        let suite = "StashTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        pieces[0] = .gem(gem(0))
        pieces[1] = .gem(gem(1))
        defaults.set(
            try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard, pieces: pieces)),
            forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertEqual(board.stash.slots.count, 1)
        XCTAssertTrue(board.stash.isEmpty)
        XCTAssertFalse(board.stashGem(at: 2))
        XCTAssertFalse(board.stashGem(at: -1))
        XCTAssertTrue(board.stashGem(at: 0))
        XCTAssertTrue(board.pieces[0].isRock)
        XCTAssertEqual(board.stash.slots[0], gem(0))
        XCTAssertFalse(board.stashGem(at: 1))
        XCTAssertEqual(board.pieces[1], pieces[1])
        let restored = GameBoard(defaults: defaults)
        XCTAssertEqual(restored.stash, board.stash)
        XCTAssertEqual(restored.pieces, board.pieces)
        XCTAssertFalse(board.placeStashedGem(from: 1, at: 2))
        XCTAssertFalse(board.placeStashedGem(from: 0, at: 45))
        // A gem destination is replaced just as a rock destination would be.
        XCTAssertTrue(board.placeStashedGem(from: 0, at: 1))
        XCTAssertEqual(board.pieces[1], pieces[0])
        XCTAssertTrue(board.stash.isEmpty)
        XCTAssertEqual(board.destructionIndex, 1)
        XCTAssertTrue(board.isResolving)
        XCTAssertFalse(board.stashGem(at: 1))
        let duringSmoke = GameBoard(defaults: defaults)
        XCTAssertTrue(duringSmoke.stash.isEmpty)
        XCTAssertEqual(duringSmoke.pieces, board.pieces)
        try await Task.sleep(nanoseconds: 1_300_000_000)
        XCTAssertNil(board.destructionIndex)
        XCTAssertFalse(board.isResolving)
        XCTAssertTrue(board.stashGem(at: 1))
        XCTAssertTrue(board.placeStashedGem(from: 0, at: 2))
        XCTAssertEqual(board.pieces[2], pieces[0])
        XCTAssertEqual(Set(board.pieces.map(\.id)).count, 45)
        board.regenerate()
        XCTAssertNil(board.destructionIndex)
        XCTAssertTrue(board.stash.isEmpty)
    }

    @MainActor
    func testPlacementResolvesNewMatch() async throws {
        let suite = "StashMatchTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        for index in [0, 1, 9] { pieces[index] = .gem(gem(index)) }
        defaults.set(
            try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard, pieces: pieces)),
            forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertTrue(board.stashGem(at: 9))
        XCTAssertTrue(board.placeStashedGem(from: 0, at: 2))
        for _ in 0..<100 {
            if !board.isResolving { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(board.isResolving)
        XCTAssertGreaterThanOrEqual(board.coins, 3)
        XCTAssertTrue(board.stash.isEmpty)
        XCTAssertEqual(Set(board.pieces.map(\.id)).count, 45)
    }
}
