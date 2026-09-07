import SwiftUI

/// An action bar keeps placeholder destinations from changing the selected screen.
struct GameNavigationBar: View {
    let onMainMenu: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            tab("Collection", symbol: "square.grid.2x2", action: {})
            tab("Achievements", symbol: "trophy", action: {})
            tab("Shop", symbol: "bag", action: {})
            tab("Main Menu", symbol: "house", action: onMainMenu)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
        }
    }

    private func tab(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .medium))
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white.opacity(0.85))
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
