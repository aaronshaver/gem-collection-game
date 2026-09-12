import SwiftUI

struct ContentView: View {
    @State private var isPlaying = false
    #if DEBUG
    @StateObject private var board = GameBoard(defaults: UITestFixture.defaults())
    #else
    @StateObject private var board = GameBoard()
    #endif

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
