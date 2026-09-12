import XCTest
@testable import FantasyTileMatcher

final class BoardLayoutTests: XCTestCase {
    func testBoardHasFifteenCells() {
        XCTAssertEqual(BoardLayout.cellCount, 15)
    }

    func testSquareTilesUseFullBoardWithEqualEdgeAndInteriorGaps() {
        for size in [CGSize(width: 350, height: 600), CGSize(width: 390, height: 650), CGSize(width: 800, height: 240)] {
            let layout = BoardLayout(availableSize: size)
            XCTAssertEqual(layout.width, size.width)
            XCTAssertEqual(layout.height, size.height)
            XCTAssertGreaterThan(layout.tileSize, 0)
            XCTAssertGreaterThanOrEqual(layout.gap.width, 12 - 0.001)
            XCTAssertGreaterThanOrEqual(layout.gap.height, 12 - 0.001)
            let half = layout.tileSize / 2
            let first = layout.center(at: 0)
            let last = layout.center(at: 14)
            XCTAssertEqual(first.x - half, layout.gap.width, accuracy: 0.001)
            XCTAssertEqual(first.y - half, layout.gap.height, accuracy: 0.001)
            XCTAssertEqual(size.width - last.x - half, layout.gap.width, accuracy: 0.001)
            XCTAssertEqual(size.height - last.y - half, layout.gap.height, accuracy: 0.001)
            for index in 0..<15 {
                let center = layout.center(at: index)
                if index % 3 < 2 {
                    XCTAssertEqual(layout.center(at: index + 1).x - center.x - layout.tileSize,
                                   layout.gap.width, accuracy: 0.001)
                }
                if index < 12 {
                    XCTAssertEqual(layout.center(at: index + 3).y - center.y - layout.tileSize,
                                   layout.gap.height, accuracy: 0.001)
                }
            }
        }
    }

    func testZeroSpaceProducesZeroSize() {
        let layout = BoardLayout(availableSize: .zero)
        XCTAssertEqual(layout.tileSize, 0)
        XCTAssertEqual(layout.gap, .zero)
        XCTAssertEqual(layout.center(at: 14), .zero)
    }
}
