import XCTest

final class MatchingSwapTests: XCTestCase {
    @MainActor
    func testMatchingSwapMovesBothPieces() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.otherElements["gemBoard"].waitForExistence(timeout: 3))
        let coinBar = app.otherElements["coinCount"]
        let originalCoins = Int(coinBar.label.filter(\.isNumber)) ?? 0
        for _ in 0..<10 {
            let elements = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'rock-' OR identifier BEGINSWITH 'gem-'"))
                .allElementsBoundByIndex
            var labels = [String](repeating: "", count: 45)
            var identifiers = [String](repeating: "", count: 45)
            for element in elements {
                guard let index = Int(element.identifier.split(separator: "-").last ?? ""), index < 45 else { continue }
                labels[index] = element.label.components(separatedBy: ", row")[0]
                identifiers[index] = element.identifier
            }
            XCTAssertFalse(identifiers.contains(""))
            let colors = labels.map { $0 == "Rock" ? nil : $0.split(separator: " ").dropFirst().first.map(String.init) }
            if let pair = matchingPair(colors) {
                let source = app.otherElements[identifiers[pair.0]]
                let target = app.otherElements[identifiers[pair.1]]
                let from = source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                let to = target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                from.press(forDuration: 0.1, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.5)
                let rewarded = NSPredicate { _, _ in
                    let current = Int(coinBar.label.filter(\.isNumber)) ?? 0
                    return current >= originalCoins + 3
                }
                XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: rewarded, object: nil)], timeout: 10), .completed)
                let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                capture.name = "Successful Matching Swap"
                capture.lifetime = .keepAlways
                add(capture)
                return
            }
            app.buttons["Debug"].tap()
            app.buttons["regenerateField"].tap()
        }
        XCTFail("No legal swap found in ten fresh fields")
    }

    private func matchingPair(_ colors: [String?]) -> (Int, Int)? {
        for source in colors.indices {
            for target in [source + 1, source + 5] where target < 45 {
                guard (target == source + 5 || source / 5 == target / 5), colors[source] != colors[target] else { continue }
                var result = colors
                result.swapAt(source, target)
                for index in [source, target] {
                    guard let color = result[index] else { continue }
                    for step in [1, 5] {
                        for start in [index - step * 2, index - step, index] {
                            let end = start + step * 2
                            guard start >= 0, end < 45, step == 5 || start / 5 == end / 5 else { continue }
                            if result[start] == color && result[start + step] == color && result[end] == color {
                                return (source, target)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}
