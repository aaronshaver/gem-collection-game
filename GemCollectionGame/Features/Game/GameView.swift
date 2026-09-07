import SwiftUI

struct GameView: View {
    let pieces: [BoardPiece]
    let onMainMenu: () -> Void
    let onRegenerate: () -> Void
    let onSwap: (Int, Int) -> Bool
    @State private var fieldID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView()
            GemBoardView(pieces: pieces, onSwap: onSwap)
                .id(fieldID)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(SoilBackground())
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(onMainMenu: onMainMenu)
        }
        .overlay {
            #if DEBUG
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    DebugRefreshButton {
                        fieldID = UUID()
                        onRegenerate()
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            #endif
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        GameView(pieces: try! PopulationGenerator(configuration: .standard).generate(seed: 42, count: BoardLayout.cellCount), onMainMenu: {}, onRegenerate: {}, onSwap: { _, _ in false })
    }
    .preferredColorScheme(.dark)
}
