import SwiftUI

struct GameView: View {
    let pieces: [BoardPiece]
    let onMainMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView()
            GemBoardView(pieces: pieces)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(SoilBackground())
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(onMainMenu: onMainMenu)
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        GameView(pieces: try! PopulationGenerator(configuration: .standard).generate(seed: 42, count: BoardLayout.cellCount), onMainMenu: {})
    }
    .preferredColorScheme(.dark)
}
