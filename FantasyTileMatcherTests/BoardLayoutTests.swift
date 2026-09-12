import XCTest
@testable import FantasyTileMatcher

final class BoardLayoutTests: XCTestCase {
    func testBoardHasFifteenCells() {
        XCTAssertEqual(BoardLayout.cellCount, 15)
    }

    func testBoardFitsNarrowAndShortScreens() {
        for size in [CGSize(width: 350, height: 600), CGSize(width: 800, height: 240)] {
            let layout = BoardLayout(availableSize: size)
            XCTAssertLessThanOrEqual(layout.width, size.width)
            XCTAssertLessThanOrEqual(layout.height, size.height)
            XCTAssertGreaterThan(layout.tileSize, 0)
            XCTAssertLessThan(layout.tileSize, layout.cellSize)
            XCTAssertEqual(layout.width / layout.height, 3.0 / 5.0, accuracy: 0.001)
        }
    }

    func testZeroSpaceProducesZeroSize() {
        let layout = BoardLayout(availableSize: .zero)
        XCTAssertEqual(layout.cellSize, 0)
    }
}
