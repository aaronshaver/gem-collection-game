import XCTest

final class PhaseOneUITests: XCTestCase {
    @MainActor
    func testThemeQuestsDevMenuAndReset() {
        let app = XCUIApplication()
        app.launchEnvironment["FANTASY_UI_TEST_SUITE"] = "FantasyUITests.\(UUID())"
        app.launchArguments = ["--reset-ui-test-state"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Fantasy Tile Matcher"].exists)
        XCTAssertTrue(app.buttons["Tutorial"].exists)
        XCTAssertTrue(app.staticTexts["© 2026 Aaron Shaver"].exists)
        XCTAssertTrue(app.staticTexts["Version 0.3.2"].exists)
        capture("Main menu")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["tileBoard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["tile-14"].exists)
        XCTAssertFalse(app.otherElements["tile-15"].exists)
        XCTAssertFalse(app.buttons["Stash"].exists)
        XCTAssertEqual(app.staticTexts["Version 0.3.2"].exists, false)
        capture("Three by five board")
        XCTAssertTrue(app.buttons["Upgrades"].exists)
        XCTAssertFalse(app.buttons["Reset All"].exists)
        XCTAssertLessThanOrEqual(app.buttons["Dev"].frame.height, 48)
        // The fixture makes this first adjacent swap nonmatching. It must remain swapped.
        let source = app.otherElements["tile-0"]
        let target = app.otherElements["tile-1"]
        let sourceLabel = source.label.components(separatedBy: ", row")[0]
        source.press(forDuration: 0.1, thenDragTo: target)
        XCTAssertTrue(app.otherElements["tileBoard"].exists)
        XCTAssertTrue(target.label.hasPrefix(sourceLabel))
        app.buttons["Dev"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["addRandomCompletion"].tap()
        app.buttons["Quests"].tap()
        XCTAssertTrue(app.otherElements["currentQuest"].exists)
        XCTAssertTrue(app.staticTexts["Completed Quests"].exists)
        capture("Current Quest and progress")
        let human = app.buttons["quest-progress-0-Human"]
        scrollTo(human, in: app)
        XCTAssertTrue(human.isHittable)
        XCTAssertTrue((human.value as? String)?.contains("of 420") == true)
        human.tap()
        XCTAssertTrue(app.buttons["Back to Quests"].exists)
        app.buttons["Back to Quests"].tap()
        for (id, denominator) in [("1-Wizard", "336"), ("2-Wisdom", "560"), ("3-Swamp", "480")] {
            let row = app.buttons["quest-progress-" + id]
            scrollTo(row, in: app)
            XCTAssertTrue(row.isHittable)
            XCTAssertTrue((row.value as? String)?.contains("of " + denominator) == true)
            capture(id)
        }
        app.buttons["Close Quests"].tap()
        app.buttons["Dev"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["resetAll"].tap()
        XCTAssertTrue(app.alerts.buttons["Cancel"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.alerts.staticTexts.count, 1)
        capture("Reset confirmation")
        app.alerts.buttons["Cancel"].tap()
        XCTAssertEqual(app.otherElements["tile-0"].exists, true)
        app.buttons["Dev"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["resetAll"].tap()
        app.alerts.buttons["Reset All"].tap()
        XCTAssertTrue(app.staticTexts["goldCount"].exists || app.otherElements["goldCount"].exists)
        app.buttons["Dev"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        Thread.sleep(forTimeInterval: 0.4)
        capture("Dev menu")
        XCTAssertTrue(app.buttons["regenerateField"].exists)
        app.buttons["regenerateField"].tap()
        XCTAssertTrue(app.otherElements["tileBoard"].exists)
        capture("Reset board")
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.scrollViews.firstMatch.swipeUp()
        }
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
