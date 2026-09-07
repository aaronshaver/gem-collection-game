import XCTest
@testable import GemCollectionGame

final class MatchBannerSequenceTests: XCTestCase {
    func testIdenticalConsecutiveCascadesRepeatWithoutCompoundingSuffix() {
        var sequence = MatchBannerSequence()
        XCTAssertEqual(sequence.message(for: "3 Orange matched", isCascade: false), "3 Orange matched")
        XCTAssertEqual(sequence.message(for: "3 Orange matched", isCascade: true), "3 Orange matched, again!")
        XCTAssertEqual(sequence.message(for: "3 Orange matched", isCascade: true), "3 Orange matched, again!")
    }

    func testOnlyImmediatelyPrecedingExactMessageQualifies() {
        var sequence = MatchBannerSequence()
        let messages = ["3 Orange matched", "4 Orange matched", "4 Orange Dull matched",
                        "4 Orange 3-sided matched", "4 Red 3-sided matched", "3 Orange matched"]
        for message in messages { XCTAssertEqual(sequence.message(for: message, isCascade: true), message) }
    }

    func testPlayerMatchesAndNewChainsNeverGetAgain() {
        var sequence = MatchBannerSequence()
        _ = sequence.message(for: "3 Orange matched", isCascade: false)
        XCTAssertEqual(sequence.message(for: "3 Orange matched", isCascade: false), "3 Orange matched")
        var nextMove = MatchBannerSequence()
        XCTAssertEqual(nextMove.message(for: "3 Orange matched", isCascade: true), "3 Orange matched")
    }
}
