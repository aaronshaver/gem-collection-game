import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            menu.padding(.vertical, 32)
            ScrollView { menu.padding(.vertical, 24) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
            VStack(spacing: 4) {
                Text("© 2026 Aaron Shaver")
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.3.5")")
            }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
    }

    private var menu: some View {
        VStack(spacing: 40) {
            VStack(spacing: 22) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(GameTheme.accent)
                    .frame(width: 72, height: 72)
                Text("Fantasy Tile Matcher")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: 14) {
                menuButton("Play", symbol: "play.fill", isPrimary: true, action: onPlay)
                menuButton("Tutorial", symbol: "questionmark.circle", action: {})
                menuButton("Settings", symbol: "gearshape", action: {})
            }
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    private func menuButton(
        _ title: String,
        symbol: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(isPrimary ? GameTheme.background : .white)
                .background(isPrimary ? GameTheme.accent : .white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(isPrimary ? 0 : 0.12), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
