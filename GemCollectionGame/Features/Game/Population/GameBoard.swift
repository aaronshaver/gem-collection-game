import Foundation
import Combine

final class GameBoard: ObservableObject {
    struct Save: Codable {
        let seed: UInt64
        let configuration: PopulationConfiguration
        let pieces: [BoardPiece]
    }
    static let storageKey = "gameBoard.population.v1"
    @Published private(set) var pieces: [BoardPiece]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let configuration = PopulationConfiguration.standard
        // The built-in catalog is a developer-owned invariant, covered by tests.
        let generator = try! PopulationGenerator(configuration: configuration)
        let saved = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode(Save.self, from: $0) }
        let seed = saved?.seed ?? UInt64.random(in: .min ... .max)
        if let saved, saved.configuration == configuration,
           saved.pieces.count == BoardLayout.cellCount,
           saved.pieces.enumerated().allSatisfy({ $0.offset == $0.element.id }) {
            pieces = saved.pieces
        } else {
            // Import the original rock board once; unchanged rock cells keep their identity.
            let legacy = RockBoard(defaults: defaults).rocks
            pieces = generator.generate(seed: seed, count: BoardLayout.cellCount, existingRocks: legacy)
            let snapshot = Save(seed: seed, configuration: configuration, pieces: pieces)
            if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: Self.storageKey) }
        }
    }
    func regenerate() {
        let configuration = PopulationConfiguration.standard
        let seed = UInt64.random(in: .min ... .max)
        let generator = try! PopulationGenerator(configuration: configuration)
        let fresh = generator.generate(seed: seed, count: BoardLayout.cellCount)
        let snapshot = Save(seed: seed, configuration: configuration, pieces: fresh)
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.storageKey)
        }
        pieces = fresh
    }
}
