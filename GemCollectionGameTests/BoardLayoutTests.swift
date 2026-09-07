import XCTest
@testable import GemCollectionGame

final class BoardLayoutTests: XCTestCase {
    func testBoardHasFortyCells() {
        XCTAssertEqual(BoardLayout.cellCount, 40)
    }

    func testBoardFitsNarrowAndShortScreens() {
        for size in [CGSize(width: 350, height: 600), CGSize(width: 800, height: 240)] {
            let layout = BoardLayout(availableSize: size)
            XCTAssertLessThanOrEqual(layout.width, size.width)
            XCTAssertLessThanOrEqual(layout.height, size.height)
            XCTAssertGreaterThan(layout.gemDiameter, 0)
            XCTAssertLessThan(layout.gemDiameter, layout.cellSize)
            XCTAssertEqual(layout.width / layout.height, 5.0 / 8.0, accuracy: 0.001)
        }
    }

    func testZeroSpaceProducesZeroSize() {
        let layout = BoardLayout(availableSize: .zero)
        XCTAssertEqual(layout.cellSize, 0)
    }
}
