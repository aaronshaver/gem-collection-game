import XCTest

final class NavigationTests: XCTestCase {
    @MainActor
    func testMenuAndPlayNavigation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Placeholder Game Title"].exists)
        XCTAssertFalse(app.buttons["Quit"].exists)
        for title in ["How to Play", "Settings"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.buttons["Play"].exists)
        }
        capture("Main Menu")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].waitForExistence(timeout: 3))
        for title in ["Collection", "Achievements", "Shop"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.otherElements["gemBoard"].exists)
        }
        capture("Game Board")
        app.buttons["Main Menu"].tap()
        XCTAssertTrue(app.buttons["Play"].exists)
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
