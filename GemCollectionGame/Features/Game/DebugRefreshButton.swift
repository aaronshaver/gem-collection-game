import SwiftUI

#if DEBUG
struct DebugRefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 26, height: 26)
                .background(.black.opacity(0.4), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Generate fresh field")
        .accessibilityHint("Debug: replaces and saves the current rocks and gems.")
        .accessibilityIdentifier("regenerateField")
    }
}
#endif
