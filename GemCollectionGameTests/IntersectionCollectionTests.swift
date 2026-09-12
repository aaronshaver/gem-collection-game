import XCTest
@testable import GemCollectionGame

final class IntersectionCollectionTests: XCTestCase {
    private func field(exact: [Int], extras: [Int] = []) -> [BoardPiece] {
        let c = PopulationConfiguration.standard
        var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
        for index in exact + extras {
            pieces[index] = .gem(Gem(id: index, seed: UInt64(index), grade: c.grades[1],
                color: c.colors[0], shape: c.shapes[extras.contains(index) ? 1 : 0]))
        }
        return pieces
    }

    func testTConsumesSevenGemsFor42CoinsInEitherGestureDirection() {
        let pieces = field(exact: [5, 6, 7, 12, 17], extras: [8, 9])
        for source in [2, 8] {
            let batch = MatchResolution.scan(pieces, swapping: (source, 7))
            XCTAssertEqual(batch.lines.count, 2)
            XCTAssertEqual(batch.indices, [5, 6, 7, 8, 9, 12, 17])
            XCTAssertEqual(batch.coins, 42)
            var collection = GemCollection()
            collection.record(lines: batch.lines, pieces: pieces)
            XCTAssertEqual(collection.discovered.count, 1)
            XCTAssertEqual(collection.recent.count, 1)
        }
    }

    func testLAndCrossDeduplicateTheirSharedGem() {
        for indices in [[5, 6, 7, 10, 15], [2, 6, 7, 8, 12]] {
            let batch = MatchResolution.scan(field(exact: indices))
            XCTAssertEqual(batch.lines.count, 2)
            XCTAssertEqual(batch.indices, Set(indices))
            XCTAssertEqual(batch.coins, 40)
        }
    }

    func testBothAxesNeedAnExactRunThroughTheIntersection() {
        let pieces = field(exact: [5, 6, 7, 12], extras: [17])
        let batch = MatchResolution.scan(pieces, swapping: (2, 7))
        XCTAssertEqual(batch.lines, [[5, 6, 7]])
        XCTAssertEqual(batch.coins, 24)
        // Three identical gems elsewhere on a long line cannot qualify its intersection.
        let separate = field(exact: [5, 6, 7, 8, 14, 19], extras: [9])
        XCTAssertEqual(MatchResolution.scan(separate, swapping: (4, 9)).lines.count, 1)
    }

    func testGravityFormsBothExactAxes() {
        var before = field(exact: [0, 6, 7, 12, 18], extras: [8, 9])
        var after = before
        after.swapAt(0, 5)
        after.swapAt(18, 17)
        let batch = MatchResolution.scan(after, formedAfter: before)
        XCTAssertEqual(batch.indices, [5, 6, 7, 8, 9, 12, 17])
        XCTAssertEqual(batch.coins, 42)
        before = after
        XCTAssertTrue(MatchResolution.scan(after, formedAfter: before).lines.isEmpty)
    }

    @MainActor
    func testSwapSavesBothLinesAndReloadConsumesAllSeven() async throws {
        let suite = "IntersectionReload.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let pieces = field(exact: [2, 5, 6, 12, 17], extras: [8, 9])
        defaults.set(try JSONEncoder().encode(GameBoard.Save(seed: 1, configuration: .standard,
            pieces: pieces)), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertTrue(board.swap(2, 7))
        let snapshot = try XCTUnwrap(defaults.data(forKey: GameBoard.storageKey))
        let save = try JSONDecoder().decode(GameBoard.Save.self, from: snapshot)
        XCTAssertEqual(save.pendingMatchLines?.count, 2)
        board.regenerate()
        defaults.set(snapshot, forKey: GameBoard.storageKey)
        let restored = GameBoard(defaults: defaults)
        restored.resolveIfNeeded()
        for _ in 0..<100 {
            if !restored.collectedIDs.isEmpty { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(restored.collectedIDs, [2, 5, 6, 8, 9, 12, 17])
        for _ in 0..<100 {
            if restored.coins > 0 { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(restored.coins, 42)
        XCTAssertEqual(restored.collection.discovered.count, 1)
        XCTAssertTrue(Set([2, 5, 6, 8, 9, 12, 17]).isDisjoint(with: restored.pieces.map(\.id)))
        restored.regenerate()
    }

    func testCollectionMaximumUsesCatalogEntries() {
        var catalog = PopulationConfiguration.standard
        XCTAssertEqual(catalog.uniqueCombinationCount, 72)
        catalog.colors.removeLast()
        XCTAssertEqual(catalog.uniqueCombinationCount, 60)
        catalog.shapes.append(catalog.shapes[0])
        XCTAssertEqual(catalog.uniqueCombinationCount, 60)
    }
}
