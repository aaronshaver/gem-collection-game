import XCTest
@testable import GemCollectionGame

final class MatchBannerTests: XCTestCase {
    @MainActor
    func testBannersQueueInOrderWithGaps() async throws {
        let suite = "BannerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let board = GameBoard(defaults: defaults)
        board.enqueueMatchBanner(3)
        board.enqueueMatchBanner(5)
        board.enqueueMatchBanner(4)
        var states: [Int?] = []
        for _ in 0..<80 {
            try await Task.sleep(nanoseconds: 50_000_000)
            if states.isEmpty || states.last! != board.matchBannerCount {
                states.append(board.matchBannerCount)
            }
            if states.count == 6 { break }
        }
        XCTAssertEqual(states, [3, nil, 5, nil, 4, nil])
        board.regenerate()
        XCTAssertNil(board.matchBannerCount)
    }
}
