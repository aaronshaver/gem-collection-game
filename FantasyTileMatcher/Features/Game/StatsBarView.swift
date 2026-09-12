import SwiftUI

struct StatsBarView: View {
    let gold: Int
    let completed: Int

    var body: some View {
        HStack(spacing: 6) {
            CoinLabel(amount: gold)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Gold: \(gold)")
                .accessibilityIdentifier("goldCount")
            Spacer()
            Text("\(completed) of \(Adventurer.all.count) Quests Completed")
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityIdentifier("questCount")
        }
        .font(.system(.caption, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05))
    }
}
