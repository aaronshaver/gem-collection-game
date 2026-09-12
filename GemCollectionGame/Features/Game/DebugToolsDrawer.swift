import SwiftUI

#if DEBUG
struct DebugToolsDrawer: View {
    let isResolving: Bool
    let onClose: () -> Void
    let onRefresh: () -> Void
    let onPreviewDiscovery: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "ladybug").foregroundStyle(.mint)
                Text("Debug").font(.title2.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close debug")
            }
            Button(action: onRefresh) {
                Label("Refresh Board", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("regenerateField")
            Button(action: onPreviewDiscovery) {
                Label("Test New Set Collection", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("previewDiscovery")
            .disabled(isResolving)
        }
        .buttonStyle(.bordered)
        .tint(.mint)
        .padding(20)
        .background(GameBackground())
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityIdentifier("debugDrawer")
    }
}
#endif
