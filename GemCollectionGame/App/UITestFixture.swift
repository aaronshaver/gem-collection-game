#if DEBUG
import Foundation

/// UI tests use a separate save so testing never spends the player's coins.
enum UITestFixture {
    static func defaults() -> UserDefaults {
        let environment = ProcessInfo.processInfo.environment
        guard let suite = environment["GEM_UI_TEST_SUITE"], suite.hasPrefix("GemUITests."),
              let defaults = UserDefaults(suiteName: suite) else { return .standard }
        if ProcessInfo.processInfo.arguments.contains("--reset-ui-test-state") {
            defaults.removePersistentDomain(forName: suite)
            let c = PopulationConfiguration.standard
            var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
            pieces[0] = .gem(Gem(id: 0, seed: 42, grade: c.grades[2], color: c.colors[5], shape: c.shapes[2]))
            let save = GameBoard.Save(seed: 1, configuration: c, pieces: pieces, coins: 20)
            defaults.set(try! JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        }
        return defaults
    }
}
#endif
