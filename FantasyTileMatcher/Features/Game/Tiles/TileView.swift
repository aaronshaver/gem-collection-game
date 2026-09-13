import SwiftUI

/// Text-only attributes for Phase 1. The four quadrants keep a fixed reading order.
struct TileView: View {
    let adventurer: Adventurer

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    quadrant(adventurer.race.rawValue, side: side)
                    quadrant(adventurer.adventurerClass.rawValue, side: side)
                }
                HStack(spacing: 0) {
                    quadrant(adventurer.ability.rawValue, side: side)
                    quadrant(adventurer.origin.rawValue, side: side)
                }
            }
            .clipShape(Rectangle())
            .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(adventurer.label)
    }

    private func quadrant(_ text: String, side: CGFloat) -> some View {
        Text(text)
            .font(.system(size: max(9, side * 0.108), weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 2)
            .frame(width: side / 2, height: side / 2)
            .foregroundStyle(.white)
            .background { Rectangle().fill(Color(red: 0.16, green: 0.23, blue: 0.25).gradient) }
    }
}
