import XCTest
@testable import GemCollectionGame

final class BoardDragTests: XCTestCase {
    func testNeighborOnlyPullsAfterTensionThreshold() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 30, height: 0), cellSize: 100)
        XCTAssertEqual(drag.target, 7)
        XCTAssertEqual(drag.targetOffset, .zero)
        drag.update(translation: CGSize(width: 60, height: 0), cellSize: 100)
        XCTAssertGreaterThan(drag.sourceOffset.width, 0)
        XCTAssertLessThan(drag.targetOffset.width, 0)
        XCTAssertFalse(drag.rejected)
    }

    func testTwentyPercentEntryRejectsAndCannotRestartUntilFingerLifts() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 70, height: 0), cellSize: 100)
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

    func testExactBoundaryInAllDirections() {
        for direction in [CGSize(width: 1, height: 0), CGSize(width: -1, height: 0),
                          CGSize(width: 0, height: 1), CGSize(width: 0, height: -1)] {
            var drag = BoardDrag(source: 6)
            drag.update(translation: CGSize(width: direction.width * 69.9, height: direction.height * 69.9), cellSize: 100)
            XCTAssertFalse(drag.rejected)
            drag.update(translation: CGSize(width: direction.width * 70, height: direction.height * 70), cellSize: 100)
            XCTAssertTrue(drag.rejected)
        }
    }

    func testOffCenterGrabUsesFingerPosition() {
        for grab in [-20.0, 20.0] {
            var drag = BoardDrag(source: 6, touchStartOffset: CGSize(width: grab, height: 0))
            drag.update(translation: CGSize(width: 69 - grab, height: 0), cellSize: 100)
            XCTAssertFalse(drag.rejected)
            drag.update(translation: CGSize(width: 70 - grab, height: 0), cellSize: 100)
            XCTAssertTrue(drag.rejected)
        }
    }

    func testFingerMustBeInsideNeighborAcrossPerpendicularAxis() {
        var drag = BoardDrag(source: 6)
        drag.update(translation: CGSize(width: 70, height: 55), cellSize: 100)
        XCTAssertFalse(drag.rejected)
        drag.update(translation: CGSize(width: 70, height: 40), cellSize: 100)
        XCTAssertTrue(drag.rejected)
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
        drag.update(translation: CGSize(width: 60, height: 0), cellSize: 0)
        XCTAssertEqual(drag.sourceOffset, .zero)
        drag.update(translation: CGSize(width: 60, height: 0), cellSize: 100)
        drag.update(translation: .zero, cellSize: 100)
        XCTAssertEqual(drag.sourceOffset, .zero)
        XCTAssertEqual(drag.targetOffset, .zero)
        XCTAssertFalse(drag.rejected)
    }
}
