import XCTest
import SwiftUI
@testable import GemCollectionGame

final class GemAppearanceTests: XCTestCase {
    @MainActor
    func testRenderEveryCatalogCombination() throws {
        let catalog = PopulationConfiguration.standard
        let sheet = VStack(spacing: 8) {
            ForEach(catalog.grades) { grade in
                Text(grade.name).foregroundStyle(.white).font(.title2)
                ForEach(catalog.shapes) { shape in
                    HStack(spacing: 8) {
                        ForEach(catalog.colors) { color in
                            GemView(gem: Gem(id: 0, seed: 42, grade: grade, color: color, shape: shape))
                                .frame(width: 80, height: 80)
                        }
                    }
                }
            }
        }.padding(20).background(Color(white: 0.08))
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        let rendered = try XCTUnwrap(renderer.uiImage)
        let attachment = XCTAttachment(image: rendered)
        attachment.name = "All 72 Gem Variants"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
