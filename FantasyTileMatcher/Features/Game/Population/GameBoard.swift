import Foundation
import Combine
import SwiftUI

@MainActor
final class GameBoard: ObservableObject {
    struct Save: Codable {
        // Missing board data starts a fresh layout while preserving gold and completed Quests.
        var pieces: [Tile]?
        var gold: Int
        var collection: QuestCollection
    }
    static let storageKey = "fantasyTileMatcher.v1"
    @Published private(set) var pieces: [Tile]
    @Published private(set) var collection: QuestCollection
    @Published private(set) var gold: Int
    @Published private(set) var discoveryEvent = 0
    @Published private(set) var isResolving = false
    @Published private(set) var collectedIDs: Set<Int> = []
    @Published private(set) var spawnRows: [Int: Int] = [:]
    private var resolutionTask: Task<Void, Never>?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Remove obsolete pre-0.3 data; the old game has no migration or compatibility layer.
        defaults.removeObject(forKey: "gameBoard.population.v1")
        defaults.removeObject(forKey: "rockBoard.appearances.v1")
        if let data = defaults.data(forKey: Self.storageKey),
           let save = try? JSONDecoder().decode(Save.self, from: data), Self.isValid(save) {
            pieces = save.pieces ?? Self.newBoard()
            gold = save.gold
            collection = save.collection
        } else {
            pieces = Self.newBoard()
            gold = 0
            collection = QuestCollection()
        }
        persist()
    }

    private static func isValid(_ save: Save) -> Bool {
        save.gold >= 0 &&
        (save.pieces.map { $0.count == BoardLayout.cellCount && Set($0.map(\.id)).count == BoardLayout.cellCount } ?? true) &&
        (save.collection.current.map { !save.collection.completed.contains($0) } ??
         (save.collection.completed.count == Adventurer.all.count))
    }

    private static func newBoard() -> [Tile] {
        PopulationGenerator().freshField(seed: .random(in: .min ... .max))
    }

    func markCollectionRead() { collection.markRead(); persist() }

    #if DEBUG
    func previewDiscovery() { discoveryEvent += 1 }
    #endif

    private func cancelResolution() {
        resolutionTask?.cancel()
        resolutionTask = nil
        isResolving = false
        collectedIDs = []
        spawnRows = [:]
    }

    /// Refresh the board while keeping the Quest and earned progress.
    func regenerate() {
        cancelResolution()
        let nextID = (pieces.map(\.id).max() ?? 0) + 1
        pieces = PopulationGenerator().freshField(seed: .random(in: .min ... .max), startingID: nextID)
        persist()
    }

    func resetAll() {
        cancelResolution()
        pieces = Self.newBoard()
        gold = 0
        collection = QuestCollection()
        discoveryEvent = 0
        persist()
    }

    @discardableResult
    func swap(_ source: Int, _ target: Int) -> Bool {
        guard !isResolving, SwapRules.canSwap(source, target, in: pieces) else { return false }
        pieces.swapAt(source, target)
        persist()
        resolveIfNeeded()
        return true
    }

    /// A cleared board, gold and Quest completion are committed together; animation can safely restart on launch.
    func resolveIfNeeded() {
        guard !isResolving, MatchRules.hasMatch(in: pieces) else { return }
        isResolving = true
        resolutionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 260_000_000)
                while !Task.isCancelled {
                    let batch = MatchResolution.scan(self.pieces)
                    guard !batch.lines.isEmpty else { break }
                    self.collectedIDs = Set(batch.indices.map { self.pieces[$0].id })
                    try await Task.sleep(nanoseconds: UInt64(CollectionBurst.duration * 1_000_000_000))
                    try Task.checkCancellation()
                    let nextID = (self.pieces.map(\.id).max() ?? 0) + 1
                    let incoming = PopulationGenerator().generate(seed: .random(in: .min ... .max),
                                                                  count: batch.indices.count, startingID: nextID)
                    let gravity = MatchResolution.collapse(self.pieces, removing: batch.indices, replacements: incoming)
                    let completed = self.collection.record(lines: batch.lines, pieces: self.pieces)
                    self.spawnRows = gravity.spawnRows
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.pieces = gravity.pieces
                        self.collectedIDs = []
                        self.gold += batch.gold
                    }
                    self.persist()
                    if completed { self.discoveryEvent += 1 }
                    try await Task.sleep(nanoseconds: 30_000_000)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { self.spawnRows = [:] }
                    try await Task.sleep(nanoseconds: 450_000_000)
                }
                self.isResolving = false
                self.resolutionTask = nil
            } catch {
                // A cancelled task must not modify a freshly reset or regenerated board.
            }
        }
    }

    private func persist() {
        let save = Save(pieces: pieces, gold: gold, collection: collection)
        if let data = try? JSONEncoder().encode(save) { defaults.set(data, forKey: Self.storageKey) }
    }
}
