import SwiftUI

/// Text-only attributes for Phase 1. The four quadrants keep a fixed reading order.
struct TileView: View {
    let adventurer: Adventurer

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    quadrant(.race, side: side)
                    quadrant(.adventurerClass, side: side)
                }
                HStack(spacing: 0) {
                    quadrant(.ability, side: side)
                    quadrant(.origin, side: side)
                }
            }
            .clipShape(Rectangle())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(adventurer.label)
    }

    private func quadrant(_ attribute: Attribute, side: CGFloat) -> some View {
        Text(attribute.value(in: adventurer))
            .font(.system(size: max(9, side * 0.108), weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 2)
            .frame(width: side / 2, height: side / 2)
            .foregroundStyle(.white)
            .background(AttributePalette.color(for: attribute, in: adventurer))
    }
}
