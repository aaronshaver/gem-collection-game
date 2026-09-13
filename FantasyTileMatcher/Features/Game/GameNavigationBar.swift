import SwiftUI

struct GameNavigationBar: View {
    let onMainMenu: () -> Void
    let onQuests: () -> Void
    let onUpgrades: () -> Void
    var questsSelected = false
    var hasUnread = false
    var devSelected = false
    var onDev: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            tab("Main Menu", symbol: "house", action: onMainMenu)
            tab(
                "Quests", symbol: questsSelected ? "trophy.fill" : "trophy",
                selected: questsSelected, unread: hasUnread, action: onQuests)
            tab("Upgrades", symbol: "arrow.up.circle.fill", action: onUpgrades)
            #if DEBUG
            tab("Dev", symbol: "slider.horizontal.3", selected: devSelected, action: onDev)
            #endif
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
        }
    }

    private func tab(
        _ title: String, symbol: String, selected: Bool = false,
        unread: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selected ? Color.mint : .white.opacity(0.85))
                    .overlay(alignment: .topTrailing) {
                        if unread {
                            Circle().fill(Color.cyan)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color(white: 0.12), lineWidth: 2))
                                .offset(x: 8, y: -4)
                        }
                    }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(selected ? Color.mint : .white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                selected ? Color.mint.opacity(0.13) : .clear,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(unread ? "New discoveries" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
