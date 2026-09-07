import SwiftUI

struct StatsBarView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(Color.yellow)
                .accessibilityHidden(true)
            Text("0")
                .monospacedDigit()
            Spacer()
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coins: 0")
    }
}
