import SwiftUI

struct StatsBarView: View {
    let gold: Int
    let days: Int

    var body: some View {
        HStack(spacing: 6) {
            CoinLabel(amount: gold)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Gold: \(gold)")
                .accessibilityIdentifier("goldCount")
            Spacer()
            DayLabel(amount: days)
                .accessibilityIdentifier("dayCount")
        }
        .font(.system(.caption, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05))
    }
}
