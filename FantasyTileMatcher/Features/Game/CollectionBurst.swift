import SwiftUI

/// A brief tile fade replaces gem destruction; Quest confetti and haptics remain unchanged.
struct CollectionBurst: View {
    static let duration = 0.30
    let adventurer: Adventurer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var faded = false

    var body: some View {
        TileView(adventurer: adventurer)
            .overlay(Rectangle().fill(.white.opacity(faded ? 0.45 : 0)))
            .scaleEffect(reduceMotion ? 1 : (faded ? 0.75 : 1))
            .opacity(faded ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: Self.duration)) { faded = true } }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
