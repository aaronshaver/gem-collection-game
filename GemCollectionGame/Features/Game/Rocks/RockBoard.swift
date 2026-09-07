import Foundation

/// Kept above screen navigation and saved locally so rocks survive app relaunches.
final class RockBoard: ObservableObject {
    let rocks: [Rock]
    private static let storageKey = "rockBoard.appearances.v1"

    init(defaults: UserDefaults = .standard) {
        var restored: [Rock] = []
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([Rock].self, from: data),
           Set(saved.map(\.id)).count == saved.count {
            // Refresh old artwork from its original seeds, preserving rock identity.
            restored = saved.prefix(BoardLayout.cellCount).map {
                $0.generationVersion < 2 ? Rock(id: $0.id, seed: $0.seed) : $0
            }
        }
        var nextID = (restored.map(\.id).max() ?? -1) + 1
        while restored.count < BoardLayout.cellCount {
            restored.append(Rock(id: nextID, seed: UInt64.random(in: .min ... .max)))
            nextID += 1
        }
        rocks = restored
        if let data = try? JSONEncoder().encode(rocks) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
