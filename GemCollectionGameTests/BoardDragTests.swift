import XCTest
@testable import GemCollectionGame

final class BoardDragTests: XCTestCase {
    func testNeighborOnlyPullsAfterTensionThreshold() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 30, height: 0), cellSize: 100)
        XCTAssertEqual(drag.target, 7)
        XCTAssertEqual(drag.targetOffset, .zero)
        drag.update(translation: CGSize(width: 70, height: 0), cellSize: 100)
        XCTAssertGreaterThan(drag.sourceOffset.width, 0)
        XCTAssertLessThan(drag.targetOffset.width, 0)
        XCTAssertFalse(drag.rejected)
    }

    func testCenterCrossingRejectsAndCannotRestartUntilFingerLifts() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 105, height: 0), cellSize: 100)
        XCTAssertTrue(drag.rejected)
        drag.returnHome()
        XCTAssertEqual(drag.sourceOffset, .zero)
        XCTAssertEqual(drag.targetOffset, .zero)
        drag.update(translation: CGSize(width: 50, height: 0), cellSize: 100)
        XCTAssertTrue(drag.rejected)
        XCTAssertEqual(drag.sourceOffset, .zero)
    }

    func testFourDirectionsChooseOnlyAdjacentCells() {
        for (translation, target) in [(CGSize(width: 60, height: 10), 7),
                                       (CGSize(width: -60, height: 10), 5),
                                       (CGSize(width: 10, height: 60), 11),
                                       (CGSize(width: 10, height: -60), 1)] {
            var drag = BoardDrag(source: 6)
            drag.update(translation: translation, cellSize: 100)
            XCTAssertEqual(drag.target, target)
        }
    }

    func testBoardEdgesResistWithoutWrappingOrRejecting() {
        for (source, translation) in [(0, CGSize(width: -200, height: 0)),
                                       (4, CGSize(width: 200, height: 0)),
                                       (0, CGSize(width: 0, height: -200)),
                                       (44, CGSize(width: 0, height: 200))] {
            var drag = BoardDrag(source: source)
            drag.update(translation: translation, cellSize: 100)
            XCTAssertNil(drag.target)
            XCTAssertFalse(drag.rejected)
            XCTAssertLessThanOrEqual(abs(drag.sourceOffset.width), 18)
            XCTAssertLessThanOrEqual(abs(drag.sourceOffset.height), 18)
        }
    }

    func testRetreatRemovesTensionAndZeroSizeIsSafe() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 80, height: 0), cellSize: 0)
        XCTAssertEqual(drag.sourceOffset, .zero)
        drag.update(translation: CGSize(width: 80, height: 0), cellSize: 100)
        drag.update(translation: .zero, cellSize: 100)
        XCTAssertEqual(drag.sourceOffset, .zero)
        XCTAssertEqual(drag.targetOffset, .zero)
        XCTAssertFalse(drag.rejected)
    }
}
