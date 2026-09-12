import XCTest

final class StashNavigationTests: XCTestCase {
    @MainActor
    func testStashRoundTripAndCancellation() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GEM_UI_TEST_SUITE"] = "GemUITests.\(UUID())"
        app.launchArguments = ["--reset-ui-test-state"]
        app.launch()
        app.buttons["Play"].tap()
        let board = app.otherElements["gemBoard"]
        XCTAssertTrue(board.waitForExistence(timeout: 3))
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 20")
        XCTAssertEqual(app.staticTexts["collectionCount"].label, "0 of 72 collected")
        app.buttons["Stash"].tap()
        XCTAssertTrue(app.buttons["Stash"].isSelected)
        XCTAssertTrue(app.buttons["Close stash"].exists)
        XCTAssertFalse(app.buttons["Put Gem on Board"].isEnabled)
        XCTAssertTrue(app.staticTexts["0 / 1 slots"].exists)
        XCTAssertFalse(app.staticTexts["Each transfer costs 5 coins. Cancel to refund."].exists)
        capture("Empty Stash")
        app.buttons["stash-slot-0"].tap()
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 15")
        XCTAssertTrue(board.exists)
        XCTAssertTrue(app.buttons["Stash"].isSelected)
        let rock = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'rock-'")).firstMatch
        XCTAssertTrue(rock.exists)
        rock.tap()
        XCTAssertTrue(board.exists)
        XCTAssertFalse(app.buttons["Close stash"].exists)
        let prompt = app.staticTexts["Choose a gem"]
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: prompt)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 6), .completed)
        XCTAssertTrue(app.otherElements["coinCount"].isHittable)
        // Stash remains the cancellation route after the temporary prompt disappears.
        app.buttons["Stash"].tap()
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 20")
        app.buttons["Stash"].tap()
        XCTAssertTrue(app.buttons["Close stash"].exists)
        app.buttons["Close stash"].tap()
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 20")
        app.buttons["Stash"].tap()
        app.buttons["Add Gem to Stash"].tap()
        let gem = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'gem-'")).firstMatch
        XCTAssertTrue(gem.exists)
        let gemLabel = gem.label.components(separatedBy: ", row")[0]
        gem.tap()
        XCTAssertTrue(app.buttons["Close stash"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Add Gem to Stash"].isEnabled)
        XCTAssertTrue(app.buttons["Put Gem on Board"].isEnabled)
        XCTAssertEqual(app.buttons["stash-slot-0"].label, gemLabel)
        capture("Filled Stash")
        app.buttons["Close stash"].tap()
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 15")
        XCTAssertFalse(app.buttons["Stash"].isSelected)
        app.terminate()
        app.launchArguments = []
        app.launch()
        app.buttons["Play"].tap()
        app.buttons["Stash"].tap()
        XCTAssertEqual(app.buttons["stash-slot-0"].label, gemLabel)
        app.buttons["Put Gem on Board"].tap()
        XCTAssertFalse(app.buttons["stash-slot-0"].exists)
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 10")
        XCTAssertTrue(board.exists)
        XCTAssertTrue(app.staticTexts["Pick a location"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons["stash-slot-0"].label, gemLabel)
        app.buttons["Close stash"].tap()
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 15")
        app.buttons["Stash"].tap()
        app.buttons["Put Gem on Board"].tap()
        let destination = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'rock-'")).firstMatch
        let index = try XCTUnwrap(destination.identifier.split(separator: "-").last)
        destination.tap()
        let settled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "selected == false"), object: app.buttons["Stash"])
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 4), .completed)
        XCTAssertTrue(app.otherElements["gem-\(index)"].exists)
        XCTAssertEqual(app.otherElements["coinCount"].label, "Coins: 10")
        capture("Placed Stash Gem")
        app.buttons["Stash"].tap()
        XCTAssertFalse(app.buttons["Put Gem on Board"].isEnabled)
        XCTAssertTrue(app.buttons["Add Gem to Stash"].isEnabled)
        app.buttons["Close stash"].tap()
        app.buttons["Tools"].tap()
        XCTAssertTrue(board.exists)
        app.buttons["Collection"].tap()
        for color in ["red", "orange", "yellow", "green", "blue", "purple"] {
            XCTAssertEqual(app.buttons["collection-color-\(color)"].value as? String, "0 of 12")
        }
        capture("Collection Counts")
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
