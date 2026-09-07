import SwiftUI

struct ContentView: View {
    @State private var isPlaying = false
    @StateObject private var board = GameBoard()

    var body: some View {
        ZStack {
            GameBackground()
            if isPlaying {
                GameView(board: board, onMainMenu: { isPlaying = false })
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
