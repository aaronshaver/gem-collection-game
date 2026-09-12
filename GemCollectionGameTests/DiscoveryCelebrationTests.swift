import XCTest
import SwiftUI
@testable import GemCollectionGame

final class DiscoveryCelebrationTests: XCTestCase {
    @MainActor
    func testOnlyNewSetsTriggerCelebrationAndReloadDoesNotReplayIt() async throws {
        let c = PopulationConfiguration.standard
        for alreadyCollected in [false, true] {
            let suite = "DiscoveryEvent.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            var pieces = (0..<45).map { BoardPiece.rock(Rock(id: $0, seed: UInt64($0))) }
            var collection = GemCollection()
            for index in [0, 1, 2] {
                let gem = Gem(id: index, seed: UInt64(index), grade: c.grades[1], color: c.colors[0], shape: c.shapes[0])
                pieces[index] = .gem(gem)
                if alreadyCollected { collection.record(GemCombination(gem)) }
            }
            let save = GameBoard.Save(seed: 1, configuration: c, pieces: pieces, collection: collection,
                                      pendingMatchLines: [[0, 1, 2]])
            defaults.set(try JSONEncoder().encode(save), forKey: GameBoard.storageKey)
            let board = GameBoard(defaults: defaults)
            XCTAssertEqual(board.discoveryEvent, 0)
            board.resolveIfNeeded()
            for _ in 0..<100 {
                if board.coins > 0 { break }
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            XCTAssertEqual(board.coins, 24)
            XCTAssertEqual(board.discoveryEvent, alreadyCollected ? 0 : 1)
            XCTAssertEqual(board.collection.discovered.count, 1)
            XCTAssertEqual(GameBoard(defaults: defaults).discoveryEvent, 0)
            board.regenerate()
        }
    }

    func testPerColorCountsDeduplicateAndFollowCatalog() {
        var c = PopulationConfiguration.standard
        var collection = GemCollection()
        for color in [0, 0, 5] {
            collection.record(GemCombination(Gem(id: 0, seed: 42, grade: c.grades[0],
                                                 color: c.colors[color], shape: c.shapes[0])))
        }
        XCTAssertEqual(collection.count(for: "red", in: c), 1)
        XCTAssertEqual(collection.count(for: "purple", in: c), 1)
        XCTAssertEqual(collection.count(for: "blue", in: c), 0)
        XCTAssertEqual(c.combinationsPerColor, 12)
        c.shapes.removeFirst()
        XCTAssertEqual(c.combinationsPerColor, 9)
        XCTAssertEqual(collection.count(for: "red", in: c), 0)
    }

    func testShakeReturnsHomeAndReduceMotionDisablesEveryStage() {
        let size = CGSize(width: 390, height: 680)
        for progress in stride(from: 0.0, through: 3, by: 0.025) {
            let reduced = DiscoveryShake(progress: progress, enabled: false).effectValue(size: size)
            XCTAssertTrue(reduced.isIdentity)
        }
        for progress in [0.0, 1, 2, 3] {
            XCTAssertTrue(DiscoveryShake(progress: progress).effectValue(size: size).isIdentity)
        }
        XCTAssertFalse(DiscoveryShake(progress: 0.125).effectValue(size: size).isIdentity)
        XCTAssertFalse(DiscoveryShake(progress: 1.125).effectValue(size: size).isIdentity)
    }

    @MainActor
    func testRenderConfettiFromFourCorners() throws {
        let frames = HStack(spacing: 16) {
            ForEach([0.05, 0.25, 0.5], id: \.self) { progress in
                DiscoveryConfettiFrame(progress: progress)
                    .frame(width: 260, height: 450)
                    .background(Color(white: 0.08))
                    .clipped()
                    .border(.white.opacity(0.3))
            }
        }.padding(20).background(Color(white: 0.04))
        let renderer = ImageRenderer(content: frames)
        renderer.scale = 2
        let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
        attachment.name = "Four Corner Confetti"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
