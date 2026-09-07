import SwiftUI

enum GameTheme {
    static let accent = Color(red: 0.48, green: 0.91, blue: 0.77)
    static let background = Color(red: 0.04, green: 0.09, blue: 0.13)
}

struct GameBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.22, blue: 0.25), GameTheme.background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
