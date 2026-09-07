import SwiftUI

struct GameView: View {
    let rocks: [Rock]
    let onMainMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView()
            GemBoardView(rocks: rocks)
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
        GameView(rocks: (0..<BoardLayout.cellCount).map { Rock(id: $0, seed: UInt64($0)) }, onMainMenu: {})
    }
    .preferredColorScheme(.dark)
}
