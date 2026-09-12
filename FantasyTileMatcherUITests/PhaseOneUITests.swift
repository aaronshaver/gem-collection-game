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
        XCTAssertTrue(app.staticTexts["Version 0.3.1"].exists)
        capture("Main menu")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["tileBoard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["tile-14"].exists)
        XCTAssertFalse(app.otherElements["tile-15"].exists)
        XCTAssertFalse(app.buttons["Stash"].exists)
        XCTAssertEqual(app.staticTexts["Version 0.3.1"].exists, false)
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
        app.buttons["Quests"].tap()
        XCTAssertTrue(app.otherElements["currentQuest"].exists)
        XCTAssertTrue(app.staticTexts["Completed Quests"].exists)
        for race in ["Cat", "Dwarf", "Elf", "Fairy", "Goblin", "Human", "Lizard", "Orc"] {
            XCTAssertTrue(app.buttons["quests-race-\(race)"].exists)
        }
        capture("Current Quest and races")
        app.buttons["quests-race-Human"].tap()
        XCTAssertTrue(app.buttons["Back to Quests"].exists)
        app.buttons["Back to Quests"].tap()
        app.buttons["Close Quests"].tap()
        app.buttons["Dev"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["resetAll"].tap()
        XCTAssertTrue(app.alerts.buttons["Cancel"].waitForExistence(timeout: 3))
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
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
