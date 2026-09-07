import XCTest
@testable import GemCollectionGame

final class SparkleTimingTests: XCTestCase {
    func testSparklesFadeFullyOutAndReachFullBrightness() {
        let timing = SparkleTiming(seed: 123, index: 0)
        let peak = (timing.activeFraction / 2 - timing.phase + 1) * timing.period
        let off = ((1 + timing.activeFraction) / 2 - timing.phase + 1) * timing.period
        XCTAssertEqual(timing.brightness(at: peak), 1, accuracy: 0.000001)
        XCTAssertEqual(timing.brightness(at: off), 0)
        XCTAssertEqual(timing.brightness(at: peak + timing.period), 1, accuracy: 0.000001)
    }

    func testSeededRhythmsRemainStableAndDifferBetweenSparkles() {
        let original = SparkleTiming(seed: 42, index: 0)
        let restored = SparkleTiming(seed: 42, index: 0)
        XCTAssertEqual(original.period, restored.period)
        XCTAssertEqual(original.phase, restored.phase)
        XCTAssertNotEqual(original.phase, SparkleTiming(seed: 42, index: 1).phase)
        for frame in 0..<600 {
            XCTAssertTrue((0...1).contains(original.brightness(at: Double(frame) / 60)))
        }
    }
}
