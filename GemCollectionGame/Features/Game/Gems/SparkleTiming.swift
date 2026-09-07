import Foundation
import GameplayKit

/// Appearance seed + sparkle index determine a repeatable, independent rhythm.
struct SparkleTiming {
    let period: Double
    let phase: Double
    let activeFraction: Double

    init(seed: UInt64, index: Int) {
        let random = GKMersenneTwisterRandomSource(seed: seed &+ UInt64(index) &* 0x9E3779B97F4A7C15)
        period = 2.0 + Double(random.nextUniform()) * 2.0
        phase = Double(random.nextUniform())
        activeFraction = 0.35 + Double(random.nextUniform()) * 0.30
    }

    func brightness(at time: TimeInterval) -> Double {
        let cycle = time / period + phase
        let progress = cycle - floor(cycle)
        guard progress < activeFraction else { return 0 }
        let wave = sin(.pi * progress / activeFraction)
        return wave * wave
    }
}
