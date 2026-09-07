import Foundation
import Combine
import SwiftUI

final class GameBoard: ObservableObject {
    struct Save: Codable {
        let seed: UInt64
        let configuration: PopulationConfiguration
        let pieces: [BoardPiece]
        var coins: Int? = 0
        var fieldRulesVersion: Int? = 1
    }
    static let storageKey = "gameBoard.population.v1"
    @Published private(set) var pieces: [BoardPiece]
    @Published private(set) var coins: Int
    @Published private(set) var isResolving = false
    @Published private(set) var matchBannerText: String?
    @Published private(set) var collectedIDs: Set<Int> = []
    @Published private(set) var spawnRows: [Int: Int] = [:]
    private var pendingBanners: [String] = []
    private var bannerTask: Task<Void, Never>?
    private var resolutionTask: Task<Void, Never>?
    private let defaults: UserDefaults
    private var seed: UInt64

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let configuration = PopulationConfiguration.standard
        let generator = try! PopulationGenerator(configuration: configuration)
        let saved = defaults.data(forKey: Self.storageKey).flatMap { try? JSONDecoder().decode(Save.self, from: $0) }
        coins = saved?.coins ?? 0
        seed = saved?.seed ?? UInt64.random(in: .min ... .max)
        if let saved, saved.configuration == configuration,
           saved.pieces.count == BoardLayout.cellCount,
           Set(saved.pieces.map(\.id)).count == BoardLayout.cellCount,
           saved.fieldRulesVersion == 1 || !MatchRules.hasMatch(in: saved.pieces) {
            // Player-created matches are allowed in saves; only fresh fields are match-free.
            pieces = saved.pieces.map { piece in
                if case .gem(let gem) = piece, gem.generationVersion < 4 {
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

    func regenerate() {
        bannerTask?.cancel()
        bannerTask = nil
        pendingBanners = []
        resolutionTask?.cancel()
        resolutionTask = nil
        isResolving = false
        collectedIDs = []
        matchBannerText = nil
        spawnRows = [:]
        let generator = try! PopulationGenerator(configuration: .standard)
        guard let fresh = try? generator.freshField(seed: UInt64.random(in: .min ... .max)) else { return }
        seed = fresh.seed
        pieces = fresh.pieces
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

    /// Resolution belongs to the model so leaving the screen cannot lose a reward.
    func resolveIfNeeded() {
        guard !isResolving, MatchRules.hasMatch(in: pieces) else { return }
        isResolving = true
        resolutionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 260_000_000)
                var bannerSequence = MatchBannerSequence()
                var isCascade = false
                while !Task.isCancelled {
                    let batch = MatchResolution.scan(self.pieces)
                    guard !batch.lines.isEmpty else { break }
                    withAnimation(.easeOut(duration: 0.34)) {
                        for reward in batch.rewards {
                            self.enqueueMatchBanner(bannerSequence.message(for: reward.banner, isCascade: isCascade))
                        }
                        self.collectedIDs = Set(batch.indices.map { self.pieces[$0].id })
                    }
                    try await Task.sleep(nanoseconds: 380_000_000)
                    let generator = try PopulationGenerator(configuration: .standard)
                    let nextID = (self.pieces.map(\.id).max() ?? -1) + 1
                    let incoming = generator.generate(seed: UInt64.random(in: .min ... .max),
                        count: batch.indices.count, startingID: nextID)
                    let gravity = MatchResolution.collapse(self.pieces, removing: batch.indices, replacements: incoming)
                    self.spawnRows = gravity.spawnRows
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.pieces = gravity.pieces
                        self.collectedIDs = []
                        self.coins += batch.coins
                    }
                    // Commit a full board and its reward together, even if the app closes mid-animation.
                    self.persist()
                    try await Task.sleep(nanoseconds: 30_000_000)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        self.spawnRows = [:]
                    }
                    try await Task.sleep(nanoseconds: 450_000_000)
                    isCascade = true
                }
                self.isResolving = false
                self.resolutionTask = nil
            } catch is CancellationError {
                // Regeneration owns the replacement state after cancellation.
            } catch {
                self.collectedIDs = []
                self.matchBannerText = nil
                self.spawnRows = [:]
                self.isResolving = false
                self.resolutionTask = nil
            }
        }
    }

    /// FIFO presentation keeps rapid cascades from replacing earlier match notices.
    func enqueueMatchBanner(_ text: String) {
        pendingBanners.append(text)
        guard bannerTask == nil else { return }
        bannerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                while !self.pendingBanners.isEmpty {
                    try Task.checkCancellation()
                    let next = self.pendingBanners.removeFirst()
                    withAnimation(.easeOut(duration: 0.12)) { self.matchBannerText = next }
                    try await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation(.easeOut(duration: 0.15)) { self.matchBannerText = nil }
                    // Includes the fade-out and a short clear gap before the next notice.
                    try await Task.sleep(nanoseconds: 300_000_000)
                }
                self.bannerTask = nil
            } catch {
                // Regeneration clears the queue and owns the replacement presentation.
            }
        }
    }

    private func persist() {
        let snapshot = Save(seed: seed, configuration: .standard, pieces: pieces, coins: coins)
        if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: Self.storageKey) }
    }
}
