import XCTest
@testable import FantasyTileMatcher

@MainActor
final class TravelTests: XCTestCase {
    private func withSave(gold: Int = 10, days: Int = 0,
                          run: (GameBoard, UserDefaults) async throws -> Void) async throws {
        let suite = "TravelTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let pieces = try XCTUnwrap((0..<100).lazy.map {
            PopulationGenerator().freshField(seed: UInt64($0))
        }.first { !MatchRules.hasMatch(in: $0) })
        let save = GameBoard.Save(pieces: pieces, gold: gold, collection: QuestCollection(), days: days)
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        defer { board.resetAll() }
        try await run(board, defaults)
    }

    func testTravelWaitsForFadeThenCommitsCostsBoardAndSave() async throws {
        try await withSave(gold: 2, days: 7) { board, defaults in
            let original = board.pieces
            let quest = board.collection
            XCTAssertTrue(board.travelToNearbyTown())
            XCTAssertTrue(board.isTraveling)
            XCTAssertFalse(board.canTravel)
            XCTAssertFalse(board.travelToNearbyTown())
            XCTAssertFalse(board.swap(0, 1))
            try await Task.sleep(nanoseconds: 100_000_000)
            XCTAssertEqual(board.pieces, original)
            XCTAssertEqual(board.gold, 2)
            XCTAssertEqual(board.days, 7)
            for _ in 0..<100 {
                if !board.isTraveling { break }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            XCTAssertFalse(board.isTraveling)
            XCTAssertEqual(board.gold, 0)
            XCTAssertEqual(board.days, 8)
            XCTAssertEqual(board.collection, quest)
            XCTAssertEqual(board.pieces.count, 15)
            XCTAssertTrue(Set(original.map(\.id)).isDisjoint(with: board.pieces.map(\.id)))
            let reloaded = GameBoard(defaults: defaults)
            XCTAssertEqual(reloaded.pieces, board.pieces)
            XCTAssertEqual(reloaded.gold, board.gold)
            XCTAssertEqual(reloaded.days, board.days)
            XCTAssertEqual(reloaded.collection, quest)
        }
    }

    func testInsufficientGoldDoesNotChangeProgress() async throws {
        try await withSave(gold: 1) { board, _ in
            let pieces = board.pieces
            XCTAssertFalse(board.canTravel)
            XCTAssertFalse(board.travelToNearbyTown())
            XCTAssertEqual(board.pieces, pieces)
            XCTAssertEqual(board.gold, 1)
            XCTAssertEqual(board.days, 0)
            XCTAssertFalse(board.isTraveling)
        }
    }

    func testResetCancelsTravelAndResetsDays() async throws {
        try await withSave(days: 12) { board, defaults in
            XCTAssertTrue(board.travelToNearbyTown())
            board.resetAll()
            let pieces = board.pieces
            try await Task.sleep(nanoseconds: 350_000_000)
            XCTAssertEqual(board.pieces, pieces)
            XCTAssertEqual(board.gold, 0)
            XCTAssertEqual(board.days, 0)
            XCTAssertFalse(board.isTraveling)
            XCTAssertEqual(GameBoard(defaults: defaults).days, 0)
        }
    }

    func testRefreshCancelsTravelWithoutChargingOrResettingDays() async throws {
        try await withSave(days: 12) { board, _ in
            XCTAssertTrue(board.travelToNearbyTown())
            board.regenerate()
            let pieces = board.pieces
            try await Task.sleep(nanoseconds: 350_000_000)
            XCTAssertEqual(board.pieces, pieces)
            XCTAssertEqual(board.gold, 10)
            XCTAssertEqual(board.days, 12)
            XCTAssertFalse(board.isTraveling)
        }
    }

    func testOldSaveDefaultsDaysToZeroWithoutLosingProgress() async throws {
        try await withSave(gold: 123) { board, defaults in
            let data = try XCTUnwrap(defaults.data(forKey: GameBoard.storageKey))
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            json.removeValue(forKey: "days")
            defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: GameBoard.storageKey)
            let reloaded = GameBoard(defaults: defaults)
            XCTAssertEqual(reloaded.days, 0)
            XCTAssertEqual(reloaded.gold, 123)
            XCTAssertEqual(reloaded.pieces, board.pieces)
            XCTAssertEqual(reloaded.collection, board.collection)
        }
    }

    func testResolvingMatchBlocksTravel() async throws {
        try await withSave { board, defaults in
            let pieces = (0..<15).map { Tile(id: $0, adventurer: Adventurer.all[0]) }
            let save = GameBoard.Save(pieces: pieces, gold: 10, collection: QuestCollection())
            defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
            let matchingBoard = GameBoard(defaults: defaults)
            matchingBoard.resolveIfNeeded()
            XCTAssertTrue(matchingBoard.isResolving)
            XCTAssertFalse(matchingBoard.travelToNearbyTown())
            XCTAssertEqual(matchingBoard.days, 0)
            matchingBoard.resetAll()
        }
    }
}
