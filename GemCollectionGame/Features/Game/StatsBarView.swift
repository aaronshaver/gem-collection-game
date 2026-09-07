import SwiftUI

struct StatsBarView: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(Color.yellow)
                .accessibilityHidden(true)
            Text("\(coins)")
                .monospacedDigit()
            Spacer()
        }
        .font(.system(.caption, design: .default, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coins: \(coins)")
        .accessibilityIdentifier("coinCount")
    }
}
