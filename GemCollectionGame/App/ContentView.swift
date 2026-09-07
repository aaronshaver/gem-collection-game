import SwiftUI

struct ContentView: View {
    @State private var isPlaying = false
    @StateObject private var board = GameBoard()

    var body: some View {
        ZStack {
            GameBackground()
            if isPlaying {
                GameView(pieces: board.pieces, onMainMenu: { isPlaying = false }, onRegenerate: board.regenerate, onSwap: board.swap)
            } else {
                MainMenuView(onPlay: { isPlaying = true })
            }
        }
        .tint(GameTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
