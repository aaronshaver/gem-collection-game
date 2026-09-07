import XCTest
@testable import GemCollectionGame

final class MatchBannerTests: XCTestCase {
    @MainActor
    func testBannersQueueInOrderWithGaps() async throws {
        let suite = "BannerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let board = GameBoard(defaults: defaults)
        board.enqueueMatchBanner("3 Red matched")
        board.enqueueMatchBanner("5 Green Shiny 5-sided matched")
        board.enqueueMatchBanner("4 Blue Dull matched")
        var states: [String?] = []
        for _ in 0..<120 {
            try await Task.sleep(nanoseconds: 50_000_000)
            if states.isEmpty || states.last! != board.matchBannerText {
                states.append(board.matchBannerText)
            }
            if states.count == 6 { break }
        }
        XCTAssertEqual(states, ["3 Red matched", nil, "5 Green Shiny 5-sided matched", nil, "4 Blue Dull matched", nil])
        board.regenerate()
        XCTAssertNil(board.matchBannerText)
    }
}
