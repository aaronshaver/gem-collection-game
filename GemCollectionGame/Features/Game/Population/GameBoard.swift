import Foundation
import Combine
import SwiftUI

final class GameBoard: ObservableObject {
    enum StashAction: String, Codable { case storing, placing }
    static let stashCost = 5

    struct Save: Codable {
        let seed: UInt64
        let configuration: PopulationConfiguration
        let pieces: [BoardPiece]
        var coins: Int? = 0
        var fieldRulesVersion: Int? = 1
        /// Legacy single-line save field; pendingMatchLines stores intersections in newer saves.
        var pendingMatch: [Int]? = nil
        var collection: GemCollection? = nil
        var stash: GemStash? = nil
        var pendingMatchLines: [[Int]]? = nil
        var pendingStashAction: StashAction? = nil
    }
    static let storageKey = "gameBoard.population.v1"
    @Published private(set) var pieces: [BoardPiece]
    @Published private(set) var collection: GemCollection
    @Published private(set) var discoveryEvent = 0
    @Published private(set) var stash: GemStash
    @Published private(set) var destructionIndex: Int?
    @Published private(set) var coins: Int
    @Published private(set) var pendingStashAction: StashAction?
    @Published private(set) var isResolving = false
    @Published private(set) var collectedIDs: Set<Int> = []
    @Published private(set) var spawnRows: [Int: Int] = [:]
    private var resolutionTask: Task<Void, Never>?
    private let defaults: UserDefaults
    private var pendingMatch: [[Int]]?
    private var seed: UInt64

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let configuration = PopulationConfiguration.standard
        let generator = try! PopulationGenerator(configuration: configuration)
        let saved = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode(Save.self, from: $0) }
        // A selection cannot resume after relaunch, so return its reserved coins.
        coins = (saved?.coins ?? 0) + (saved?.pendingStashAction == nil ? 0 : Self.stashCost)
        collection = saved?.collection ?? GemCollection()
        stash = saved?.stash ?? GemStash()
        seed = saved?.seed ?? UInt64.random(in: .min ... .max)
        if let saved, saved.configuration == configuration,
           saved.pieces.count == BoardLayout.cellCount,
           Set(saved.pieces.map(\.id)).count == BoardLayout.cellCount,
           saved.fieldRulesVersion == 1 || !MatchRules.hasMatch(in: saved.pieces) {
            // Player-created matches are allowed in saves; only fresh fields are match-free.
            pendingMatch = saved.pendingMatchLines ?? saved.pendingMatch.map { $0.isEmpty ? [] : [$0] }
            pieces = saved.pieces.map { piece in
                if case .gem(let gem) = piece, gem.generationVersion < 5 {
                    return .gem(Gem(id: gem.id, seed: gem.seed, grade: gem.grade, color: gem.color, shape: gem.shape))
                }
                return piece
            }
        } else {
            let legacy = RockBoard(defaults: defaults).rocks
            let fresh = try! generator.freshField(seed: seed, existingRocks: legacy)
            seed = fresh.seed
            pieces = fresh.pieces
        }
        persist()
    }

    func markCollectionRead() {
        collection.markRead()
        persist()
    }

    #if DEBUG
    func previewDiscovery() {
        discoveryEvent += 1
    }
    #endif

    func regenerate() {
        cancelStashAction()
        resolutionTask?.cancel()
        resolutionTask = nil
        isResolving = false
        destructionIndex = nil
        pendingMatch = nil
        collectedIDs = []
        spawnRows = [:]
        let generator = try! PopulationGenerator(configuration: .standard)
        guard let fresh = try? generator.freshField(seed: UInt64.random(in: .min ... .max)) else { return }
        seed = fresh.seed
        pieces = fresh.pieces
        persist()
    }

    private var nextPieceID: Int {
        (pieces.map(\.id) + stash.slots.compactMap { $0?.id }).max().map { $0 + 1 } ?? 0
    }

    @discardableResult
    func beginStashAction(_ action: StashAction) -> Bool {
        guard !isResolving, pendingStashAction == nil, coins >= Self.stashCost,
              action == .storing ? stash.hasFreeSlot : !stash.isEmpty else { return false }
        coins -= Self.stashCost
        pendingStashAction = action
        persist()
        return true
    }

    func cancelStashAction() {
        guard pendingStashAction != nil else { return }
        coins += Self.stashCost
        pendingStashAction = nil
        persist()
    }

    @discardableResult
    func stashGem(at index: Int) -> Bool {
        guard !isResolving, pendingStashAction == .storing, pieces.indices.contains(index),
              case .gem(let gem) = pieces[index], stash.hasFreeSlot else { return false }
        let rock = Rock(id: nextPieceID, seed: UInt64.random(in: .min ... .max))
        guard stash.insert(gem) else { return false }
        pendingStashAction = nil
        pieces[index] = .rock(rock)
        pendingMatch = nil
        persist()
        return true
    }

    @discardableResult
    func placeStashedGem(from slot: Int, at index: Int) -> Bool {
        guard !isResolving, pendingStashAction == .placing, pieces.indices.contains(index),
              stash.slots.indices.contains(slot), let gem = stash.slots[slot] else { return false }
        let previous = pieces
        _ = stash.remove(at: slot)
        pendingStashAction = nil
        pieces[index] = .gem(gem)
        pendingMatch = MatchResolution.scan(pieces, formedAfter: previous).lines
        // Save the transfer atomically; the debris is presentation only.
        persist()
        destructionIndex = index
        isResolving = true
        resolutionTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(DestructionEffect.duration * 1_000_000_000)) }
            catch { return }
            guard let self else { return }
            self.destructionIndex = nil
            self.isResolving = false
            self.resolutionTask = nil
            self.resolveIfNeeded()
        }
        return true
    }

    @discardableResult
    func swap(_ source: Int, _ target: Int) -> Bool {
        guard !isResolving, pendingStashAction == nil, SwapRules.canSwap(source, target, in: pieces) else { return false }
        pieces.swapAt(source, target)
        pendingMatch = MatchResolution.scan(pieces, swapping: (source, target)).lines
        persist()
        resolveIfNeeded()
        return true
    }

    /// Resolution belongs to the model so leaving the screen cannot lose a reward.
    func resolveIfNeeded() {
        guard !isResolving, pendingStashAction == nil, MatchRules.hasMatch(in: pieces) else { return }
        isResolving = true
        resolutionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 260_000_000)
                while !Task.isCancelled {
                    let batch: MatchBatch
                    if let lines = self.pendingMatch {
                        batch = .resolved(lines: lines, pieces: self.pieces)
                    } else {
                        batch = MatchResolution.scan(self.pieces)
                    }
                    guard !batch.lines.isEmpty else { break }
                    self.collectedIDs = Set(batch.indices.map { self.pieces[$0].id })
                    try await Task.sleep(nanoseconds: UInt64(CollectionBurst.duration * 1_000_000_000))
                    let generator = try PopulationGenerator(configuration: .standard)
                    let nextID = self.nextPieceID
                    let incoming = generator.generate(seed: UInt64.random(in: .min ... .max),
                        count: batch.indices.count, startingID: nextID)
                    let gravity = MatchResolution.collapse(self.pieces, removing: batch.indices, replacements: incoming)
                    self.pendingMatch = MatchResolution.scan(gravity.pieces, formedAfter: self.pieces).lines
                    self.spawnRows = gravity.spawnRows
                    let previousDiscoveryCount = self.collection.discovered.count
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.collection.record(lines: batch.lines, pieces: self.pieces)
                        self.pieces = gravity.pieces
                        self.collectedIDs = []
                        self.coins += batch.coins
                    }
                    // Commit a full board and its reward together, even if the app closes mid-animation.
                    self.persist()
                    if self.collection.discovered.count > previousDiscoveryCount { self.discoveryEvent += 1 }
                    try await Task.sleep(nanoseconds: 30_000_000)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.spawnRows = [:]
                    }
                    try await Task.sleep(nanoseconds: 450_000_000)
                }
                self.isResolving = false
                self.resolutionTask = nil
            } catch is CancellationError {
                // Regeneration owns the replacement state after cancellation.
            } catch {
                self.collectedIDs = []
                self.spawnRows = [:]
                self.isResolving = false
                self.resolutionTask = nil
            }
        }
    }

    private func persist() {
        let snapshot = Save(seed: seed, configuration: .standard, pieces: pieces, coins: coins,
                            pendingMatch: pendingMatch.map { $0.first ?? [] }, collection: collection, stash: stash,
                            pendingMatchLines: pendingMatch, pendingStashAction: pendingStashAction)
        if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: Self.storageKey) }
    }
}
