import XCTest
@testable import GemCollectionGame

final class MatchRulesTests: XCTestCase {
    private func field() -> [BoardPiece] {
        (0..<45).map { .rock(Rock(id: $0, seed: UInt64($0))) }
    }
    private func gem(_ id: Int, color: Int = 0, grade: Int = 0, shape: Int = 0) -> BoardPiece {
        let c = PopulationConfiguration.standard
        return .gem(Gem(id: id, seed: UInt64(id), grade: c.grades[grade], color: c.colors[color], shape: c.shapes[shape]))
    }

    func testHorizontalVerticalAndMixedGradesAndShapes() {
        for indices in [[0, 1, 2], [0, 5, 10], [1, 6, 11, 16]] {
            var pieces = field()
            for (offset, index) in indices.enumerated() {
                pieces[index] = gem(index, grade: offset % 3, shape: offset % 4)
            }
            XCTAssertTrue(MatchRules.hasMatch(in: pieces))
            XCTAssertTrue(MatchRules.matches(at: indices[1], in: pieces))
        }
    }

    func testDiagonalBentAndWrappedLinesDoNotMatch() {
        for indices in [[0, 6, 12], [0, 1, 6], [4, 5, 6]] {
            var pieces = field()
            for index in indices { pieces[index] = gem(index) }
            XCTAssertFalse(MatchRules.hasMatch(in: pieces))
        }
    }

    func testUserExampleAndReverseDragBothWork() {
        var pieces = field()
        for index in [0, 1, 7] { pieces[index] = gem(index) }
        XCTAssertTrue(SwapRules.canSwap(7, 2, in: pieces))
        XCTAssertTrue(SwapRules.canSwap(2, 7, in: pieces))
        pieces[2] = gem(2, color: 1)
        XCTAssertTrue(SwapRules.canSwap(2, 7, in: pieces))
        XCTAssertFalse(SwapRules.canSwap(0, 1, in: pieces))
        XCTAssertFalse(SwapRules.canSwap(7, 3, in: pieces))
        XCTAssertFalse(SwapRules.canSwap(-1, 2, in: pieces))
    }

    func testScreenshotRedGemCanSwapLeftIntoHorizontalMatch() {
        var pieces = field()
        // Screenshot's four visible columns, offset within the five-column board.
        for index in [1, 2, 6, 7, 9] { pieces[index] = gem(index) }
        XCTAssertTrue(SwapRules.canSwap(9, 8, in: pieces))
        XCTAssertTrue(SwapRules.canSwap(8, 9, in: pieces))
        pieces.swapAt(9, 8)
        let batch = MatchResolution.scan(pieces, swapping: (9, 8))
        XCTAssertEqual(batch.lines, [[6, 7, 8]])
        XCTAssertEqual(batch.indices.count, 3)
    }

    func testVerticalSwapCanCompleteASoleVerticalLine() {
        var pieces = field()
        for index in [0, 5, 15] { pieces[index] = gem(index) }
        XCTAssertTrue(SwapRules.canSwap(15, 10, in: pieces))
        XCTAssertTrue(SwapRules.canSwap(10, 15, in: pieces))
        pieces.swapAt(15, 10)
        XCTAssertEqual(MatchResolution.scan(pieces, swapping: (15, 10)).lines, [[0, 5, 10]])
    }

    func testUnrelatedMatchDoesNotAuthorizeSwap() {
        var pieces = field()
        for index in [0, 1, 2, 20] { pieces[index] = gem(index) }
        XCTAssertFalse(SwapRules.canSwap(20, 21, in: pieces))
        XCTAssertFalse(SwapRules.canSwap(43, 44, in: pieces))
    }

    func testWholeFieldRerollsAndRecordsReproducibleSeed() throws {
        let generator = try PopulationGenerator(configuration: .standard)
        let badSeed = try XCTUnwrap((0..<100).first { MatchRules.hasMatch(in: generator.generate(seed: UInt64($0), count: 45)) })
        let fresh = try generator.freshField(seed: UInt64(badSeed))
        XCTAssertGreaterThan(fresh.attempts, 1)
        XCTAssertFalse(MatchRules.hasMatch(in: fresh.pieces))
        XCTAssertEqual(fresh.pieces, generator.generate(seed: fresh.seed, count: 45))
        for seed in 0..<100 {
            XCTAssertFalse(MatchRules.hasMatch(in: try generator.freshField(seed: UInt64(seed)).pieces))
        }
    }

    func testImpossibleCatalogStopsAfterBoundedAttempts() throws {
        var config = PopulationConfiguration.standard
        config.gemProbability = 1
        config.colors = [config.colors[0]]
        XCTAssertThrowsError(try PopulationGenerator(configuration: config).freshField(seed: 1, maximumAttempts: 3))
    }

    func testSwapPersistsIdentityAndPlayerCreatedMatches() throws {
        let suite = "SwapTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var pieces = field()
        for index in [0, 1, 7] { pieces[index] = gem(index) }
        let save = GameBoard.Save(seed: 123, configuration: .standard, pieces: pieces)
        defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        let board = GameBoard(defaults: defaults)
        XCTAssertFalse(board.swap(30, 31))
        XCTAssertEqual(board.pieces, pieces)
        XCTAssertTrue(board.swap(2, 7))
        XCTAssertEqual(board.pieces[2], pieces[7])
        XCTAssertEqual(board.pieces[7], pieces[2])
        XCTAssertTrue(MatchRules.hasMatch(in: board.pieces))
        XCTAssertEqual(board.pieces, GameBoard(defaults: defaults).pieces)
    }
}
