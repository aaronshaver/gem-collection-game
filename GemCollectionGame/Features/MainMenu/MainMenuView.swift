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
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
    }

    private var menu: some View {
        VStack(spacing: 40) {
            VStack(spacing: 22) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(GameTheme.accent)
                    .accessibilityHidden(true)
                Text("Placeholder Game Title")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(spacing: 14) {
                menuButton("Play", symbol: "play.fill", isPrimary: true, action: onPlay)
                menuButton("How to Play", symbol: "questionmark.circle", action: {})
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
