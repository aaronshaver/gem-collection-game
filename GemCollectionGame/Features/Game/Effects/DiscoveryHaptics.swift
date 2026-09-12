import CoreHaptics
import Combine
import UIKit

@MainActor
final class DiscoveryHaptics: ObservableObject {
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    func play() {
        guard UIApplication.shared.applicationState == .active,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            if engine == nil {
                let engine = try CHHapticEngine()
                engine.playsHapticsOnly = true
                engine.isAutoShutdownEnabled = true
                engine.resetHandler = { [weak self] in
                    Task { @MainActor in self?.engine = nil; self?.player = nil }
                }
                self.engine = engine
            }
            guard let engine else { return }
            try engine.start()
            try player?.stop(atTime: CHHapticTimeImmediate)
            let buzz = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                CHHapticEventParameter(parameterID: .attackTime, value: 0.04),
                CHHapticEventParameter(parameterID: .releaseTime, value: 0.15)
            ], relativeTime: 0, duration: 0.65)
            let pattern = try CHHapticPattern(events: [buzz], parameters: [])
            player = try engine.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            engine = nil
            player = nil
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        engine?.stop(completionHandler: nil)
        player = nil
        engine = nil
    }
}
