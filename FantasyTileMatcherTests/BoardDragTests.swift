import XCTest
@testable import FantasyTileMatcher

final class BoardDragTests: XCTestCase {
    func testUnequalBoardSpacingUsesTravelAxisAndPerpendicularBounds() {
        let spacing = CGSize(width: 100, height: 160)
        var horizontal = BoardDrag(source: 4)
        horizontal.update(translation: CGSize(width: 70, height: 60), spacing: spacing)
        XCTAssertTrue(horizontal.thresholdReached)
        XCTAssertEqual(horizontal.target, 5)

        var vertical = BoardDrag(source: 4)
        vertical.update(translation: CGSize(width: 0, height: 111), spacing: spacing)
        XCTAssertFalse(vertical.thresholdReached)
        vertical.update(translation: CGSize(width: 51, height: 112), spacing: spacing)
        XCTAssertFalse(vertical.thresholdReached)
        vertical.update(translation: CGSize(width: 50, height: 112), spacing: spacing)
        XCTAssertTrue(vertical.thresholdReached)
        XCTAssertEqual(vertical.target, 7)
    }

    func testNeighborOnlyPullsAfterTensionThreshold() {
        var drag = BoardDrag(source: 4)
        drag.update(translation: CGSize(width: 30, height: 0), spacing: CGSize(width: 100, height: 100))
        XCTAssertEqual(drag.target, 5)
        XCTAssertEqual(drag.targetOffset, .zero)
        drag.update(translation: CGSize(width: 60, height: 0), spacing: CGSize(width: 100, height: 100))
        XCTAssertGreaterThan(drag.sourceOffset.width, 0)
        XCTAssertLessThan(drag.targetOffset.width, 0)
        XCTAssertFalse(drag.thresholdReached)
    }

    func testTwentyPercentEntryCommitsAndCannotRestartUntilFingerLifts() {
        var drag = BoardDrag(source: 4)
        drag.update(translation: CGSize(width: 70, height: 0), spacing: CGSize(width: 100, height: 100))
        XCTAssertTrue(drag.thresholdReached)
        drag.returnHome()
        XCTAssertEqual(drag.sourceOffset, .zero)
        XCTAssertEqual(drag.targetOffset, .zero)
        drag.update(translation: CGSize(width: 50, height: 0), spacing: CGSize(width: 100, height: 100))
        XCTAssertTrue(drag.thresholdReached)
        XCTAssertEqual(drag.sourceOffset, .zero)
    }

    func testFourDirectionsChooseOnlyAdjacentCells() {
        for (translation, target) in [(CGSize(width: 60, height: 10), 5),
                                       (CGSize(width: -60, height: 10), 3),
                                       (CGSize(width: 10, height: 60), 7),
                                       (CGSize(width: 10, height: -60), 1)] {
            var drag = BoardDrag(source: 4)
            drag.update(translation: translation, spacing: CGSize(width: 100, height: 100))
            XCTAssertEqual(drag.target, target)
        }
    }

    func testExactBoundaryInAllDirections() {
        for direction in [CGSize(width: 1, height: 0), CGSize(width: -1, height: 0),
                          CGSize(width: 0, height: 1), CGSize(width: 0, height: -1)] {
            var drag = BoardDrag(source: 4)
            drag.update(translation: CGSize(width: direction.width * 69.9, height: direction.height * 69.9), spacing: CGSize(width: 100, height: 100))
            XCTAssertFalse(drag.thresholdReached)
            drag.update(translation: CGSize(width: direction.width * 70, height: direction.height * 70), spacing: CGSize(width: 100, height: 100))
            XCTAssertTrue(drag.thresholdReached)
        }
    }

    func testOffCenterGrabUsesFingerPosition() {
        for grab in [-20.0, 20.0] {
            var drag = BoardDrag(source: 4, touchStartOffset: CGSize(width: grab, height: 0))
            drag.update(translation: CGSize(width: 69 - grab, height: 0), spacing: CGSize(width: 100, height: 100))
            XCTAssertFalse(drag.thresholdReached)
            drag.update(translation: CGSize(width: 70 - grab, height: 0), spacing: CGSize(width: 100, height: 100))
            XCTAssertTrue(drag.thresholdReached)
        }
    }

    func testFingerMustBeInsideNeighborAcrossPerpendicularAxis() {
        var drag = BoardDrag(source: 4)
        drag.update(translation: CGSize(width: 70, height: 55), spacing: CGSize(width: 100, height: 100))
        XCTAssertFalse(drag.thresholdReached)
        drag.update(translation: CGSize(width: 70, height: 40), spacing: CGSize(width: 100, height: 100))
        XCTAssertTrue(drag.thresholdReached)
    }

    func testBoardEdgesResistWithoutWrappingOrRejecting() {
        for (source, translation) in [(0, CGSize(width: -200, height: 0)),
                                       (2, CGSize(width: 200, height: 0)),
                                       (0, CGSize(width: 0, height: -200)),
                                       (14, CGSize(width: 0, height: 200))] {
            var drag = BoardDrag(source: source)
            drag.update(translation: translation, spacing: CGSize(width: 100, height: 100))
            XCTAssertNil(drag.target)
            XCTAssertFalse(drag.thresholdReached)
            XCTAssertLessThanOrEqual(abs(drag.sourceOffset.width), 18)
            XCTAssertLessThanOrEqual(abs(drag.sourceOffset.height), 18)
        }
    }

    func testRetreatRemovesTensionAndZeroSizeIsSafe() {
        var drag = BoardDrag(source: 4)
        drag.update(translation: CGSize(width: 60, height: 0), spacing: .zero)
        XCTAssertEqual(drag.sourceOffset, .zero)
        drag.update(translation: CGSize(width: 60, height: 0), spacing: CGSize(width: 100, height: 100))
        drag.update(translation: .zero, spacing: CGSize(width: 100, height: 100))
        XCTAssertEqual(drag.sourceOffset, .zero)
        XCTAssertEqual(drag.targetOffset, .zero)
        XCTAssertFalse(drag.thresholdReached)
    }
}
