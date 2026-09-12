import XCTest
import SwiftUI
@testable import GemCollectionGame

final class CollectionAppearanceTests: XCTestCase {
    @MainActor
    func testRenderCompactDestructionStages() throws {
        let sheet = HStack(spacing: 12) {
            ForEach([0.15, 0.35, 0.55, 0.8], id: \.self) { progress in
                DestructionFrame(progress: progress)
                    .frame(width: 64, height: 64)
                    .border(.white.opacity(0.4))
                    .frame(width: 140, height: 180)
            }
        }.padding(20).background(Color(white: 0.08))
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
        attachment.name = "Compact Destruction Stages"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testRenderShatterStagesInGemColors() throws {
        let catalog = PopulationConfiguration.standard
        let stages = [0.0, 0.25, 0.50, 0.75]
        let sheet = VStack(spacing: 12) {
            ForEach([0, 3, 4], id: \.self) { color in
                HStack(spacing: 12) {
                    ForEach(stages, id: \.self) { progress in
                        VStack {
                            Text("\(Int(progress * 100))%")
                            CollectionShatterFrame(gem: Gem(id: 0, seed: 42, grade: catalog.grades[1],
                                color: catalog.colors[color], shape: catalog.shapes[3]), progress: progress)
                                .frame(width: 100, height: 100)
                                .frame(height: 240, alignment: .top)
                        }
                    }
                }
            }
        }.padding(20).foregroundStyle(.white).background(Color(white: 0.08))
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
        attachment.name = "Falling Shards by Color and Stage"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
