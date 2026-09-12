import XCTest

final class NavigationTests: XCTestCase {
    @MainActor
    func testMenuAndPlayNavigation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Gem Find & Collect"].exists)
        XCTAssertFalse(app.buttons["Quit"].exists)
        for title in ["How to Play", "Settings"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.buttons["Play"].exists)
        }
        capture("Main Menu")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].waitForExistence(timeout: 3))
        app.buttons["Collection"].tap()
        XCTAssertTrue(app.buttons["Close collection"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Collection"].isSelected)
        XCTAssertEqual(app.buttons["Collection"].value as? String, "")
        capture("Collection Overview")
        app.buttons["collection-color-red"].tap()
        XCTAssertTrue(app.buttons["Back to collection"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["collection-entry-red-cracked-triangle"].exists)
        capture("Red Collection")
        app.buttons["Back to collection"].tap()
        XCTAssertTrue(app.buttons["collection-color-red"].exists)
        app.buttons["Close collection"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].exists)
        XCTAssertFalse(app.buttons["Collection"].isSelected)
        app.buttons["Tools"].tap()
        app.buttons["Debug"].tap()
        app.buttons["regenerateField"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].exists)
        capture("Game Board")
        app.buttons["Main Menu"].tap()
        XCTAssertTrue(app.buttons["Play"].exists)
        capture("Returned Main Menu")
    }

    @MainActor
    func testRejectedDragReturnsBothRocksHome() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].waitForExistence(timeout: 3))
        let pair = (0..<44).first { index in
            index % 5 < 4 && app.otherElements["rock-\(index)"].exists && app.otherElements["rock-\(index + 1)"].exists
        }
        guard let pair else { XCTFail("Expected adjacent rocks in the saved board"); return }
        let source = app.otherElements["rock-\(pair)"]
        let target = app.otherElements["rock-\(pair + 1)"]
        XCTAssertTrue(source.waitForExistence(timeout: 3))
        let originalSource = source.frame
        let originalTarget = target.frame
        let start = source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let destination = target.coordinate(withNormalizedOffset: CGVector(dx: 0.22, dy: 0.5))
        start.press(forDuration: 0.15, thenDragTo: destination, withVelocity: .slow, thenHoldForDuration: 0.5)
        XCTAssertEqual(source.frame.midX, originalSource.midX, accuracy: 1)
        XCTAssertEqual(target.frame.midX, originalTarget.midX, accuracy: 1)
        XCTAssertEqual(source.frame.midY, originalSource.midY, accuracy: 1)
        capture("Rejected Drag Returned Home")
        let early = start.withOffset(CGVector(dx: originalSource.width * 0.55, dy: 0))
        start.press(forDuration: 0.15, thenDragTo: early)
        let returned = NSPredicate { _, _ in
            abs(source.frame.midX - originalSource.midX) < 1 &&
            abs(target.frame.midX - originalTarget.midX) < 1
        }
        let settled = XCTNSPredicateExpectation(predicate: returned, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 3), .completed)
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
