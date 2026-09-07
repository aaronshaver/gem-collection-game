import SwiftUI

struct GameView: View {
    let onMainMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView()
            GemBoardView()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(onMainMenu: onMainMenu)
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        GameView(onMainMenu: {})
    }
    .preferredColorScheme(.dark)
}
