import SwiftUI

struct StatsBarView: View {
    var body: some View {
        HStack {
            Label("Score 0", systemImage: "diamond")
            Spacer()
            Text("Level 1")
            Spacer()
            Text("Moves 20")
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
        .accessibilityElement(children: .combine)
    }
}
