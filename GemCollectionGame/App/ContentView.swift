import SwiftUI

struct ContentView: View {
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            GameBackground()
            if isPlaying {
                GameView(onMainMenu: { isPlaying = false })
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
