import SwiftUI

struct GameNavigationBar: View {
    let onMainMenu: () -> Void
    let onCollection: () -> Void
    let onStash: () -> Void
    var stashSelected = false
    var collectionSelected = false
    var hasUnread = false
    var debugSelected = false
    var onDebug: () -> Void = {}

    var body: some View {
        HStack(spacing: 4) {
            tab(
                "Collection", symbol: collectionSelected ? "trophy.fill" : "trophy",
                selected: collectionSelected, unread: hasUnread, action: onCollection)
            tab(
                "Stash", symbol: stashSelected ? "archivebox.fill" : "archivebox",
                selected: stashSelected, action: onStash)
            tab("Tools", symbol: "hammer.fill", action: {})
            tab("Main Menu", symbol: "house", action: onMainMenu)
            #if DEBUG
            tab("Debug", symbol: "ladybug", selected: debugSelected, action: onDebug)
            #endif
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
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
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .medium))
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
            .frame(maxWidth: .infinity, minHeight: 56)
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
