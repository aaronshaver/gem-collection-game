import Foundation
import Combine

final class GameBoard: ObservableObject {
    struct Save: Codable {
        let seed: UInt64
        let configuration: PopulationConfiguration
        let pieces: [BoardPiece]
        var fieldRulesVersion: Int? = 1
    }
    static let storageKey = "gameBoard.population.v1"
    @Published private(set) var pieces: [BoardPiece]
    private let defaults: UserDefaults
    private var seed: UInt64

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let configuration = PopulationConfiguration.standard
        let generator = try! PopulationGenerator(configuration: configuration)
        let saved = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode(Save.self, from: $0) }
        seed = saved?.seed ?? UInt64.random(in: .min ... .max)
        if let saved, saved.configuration == configuration,
           saved.pieces.count == BoardLayout.cellCount,
           Set(saved.pieces.map(\.id)).count == BoardLayout.cellCount,
           saved.fieldRulesVersion == 1 || !MatchRules.hasMatch(in: saved.pieces) {
            // Player-created matches are allowed in saves; only fresh fields are match-free.
            pieces = saved.pieces
        } else {
            let legacy = RockBoard(defaults: defaults).rocks
            let fresh = try! generator.freshField(seed: seed, existingRocks: legacy)
            seed = fresh.seed
            pieces = fresh.pieces
        }
        persist()
    }

    func regenerate() {
        let generator = try! PopulationGenerator(configuration: .standard)
        guard let fresh = try? generator.freshField(seed: UInt64.random(in: .min ... .max)) else { return }
        seed = fresh.seed
        pieces = fresh.pieces
        persist()
    }

    @discardableResult
    func swap(_ source: Int, _ target: Int) -> Bool {
        guard SwapRules.canSwap(source, target, in: pieces) else { return false }
        pieces.swapAt(source, target)
        persist()
        return true
    }

    private func persist() {
        let snapshot = Save(seed: seed, configuration: .standard, pieces: pieces)
        if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: Self.storageKey) }
    }
}
