import XCTest
@testable import FantasyTileMatcher

final class BoardLayoutTests: XCTestCase {
    func testBoardHasFifteenCells() {
        XCTAssertEqual(BoardLayout.cellCount, 15)
    }

    func testSquareTilesUseFullBoardWithEqualEdgeAndInteriorGaps() {
        for size in [CGSize(width: 390, height: 678), CGSize(width: 393, height: 700), CGSize(width: 430, height: 730)] {
            let layout = BoardLayout(availableSize: size)
            XCTAssertEqual(layout.width, size.width)
            XCTAssertEqual(layout.height, size.height)
            XCTAssertEqual(layout.tileSize, 128)
            XCTAssertGreaterThan(layout.gap.width, 0)
            XCTAssertGreaterThan(layout.gap.height, 0)
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

    func testIPhone13ColumnSpacing() {
        let layout = BoardLayout(availableSize: CGSize(width: 390, height: 678))
        XCTAssertEqual(layout.gap.width, 1.5)
        XCTAssertEqual(layout.spacing.width, 129.5)
    }

    func testInsufficientSpaceNeverShrinksOrOverlapsTiles() {
        for size in [CGSize.zero, CGSize(width: 350, height: 600)] {
            let layout = BoardLayout(availableSize: size)
            XCTAssertEqual(layout.tileSize, 128)
            XCTAssertEqual(layout.width, 384)
            XCTAssertEqual(layout.height, 640)
            XCTAssertEqual(layout.gap, .zero)
            XCTAssertEqual(layout.center(at: 14), CGPoint(x: 320, y: 576))
        }
    }
}
