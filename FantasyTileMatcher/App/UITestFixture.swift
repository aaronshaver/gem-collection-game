#if DEBUG
import Foundation

/// UI testing has its own save, separate from the player's game.
@MainActor
enum UITestFixture {
    static func defaults() -> UserDefaults {
        let environment = ProcessInfo.processInfo.environment
        guard let suite = environment["FANTASY_UI_TEST_SUITE"], suite.hasPrefix("FantasyUITests."),
              let defaults = UserDefaults(suiteName: suite) else { return .standard }
        if ProcessInfo.processInfo.arguments.contains("--reset-ui-test-state") {
            defaults.removePersistentDomain(forName: suite)
            var pieces = PopulationGenerator().freshField(seed: 42)
            var seed: UInt64 = 42
            while true {
                var swapped = pieces
                swapped.swapAt(0, 1)
                // Keep this UI fixture still while testing the first nonmatching drag.
                if !MatchRules.hasMatch(in: pieces) && !MatchRules.hasMatch(in: swapped) { break }
                seed += 1
                pieces = PopulationGenerator().freshField(seed: seed)
            }
            let target = Adventurer(race: .human, adventurerClass: .wizard, ability: .wisdom, origin: .forest)
            var collection = QuestCollection(current: target)
            if ProcessInfo.processInfo.arguments.contains("--all-quests-complete") {
                var random = SystemRandomNumberGenerator()
                while collection.current != nil { collection.addRandomCompletions(using: &random) }
            }
            let save = GameBoard.Save(pieces: pieces, gold: 20, collection: collection)
            defaults.set(try! JSONEncoder().encode(save), forKey: GameBoard.storageKey)
        }
        return defaults
    }
}
#endif
