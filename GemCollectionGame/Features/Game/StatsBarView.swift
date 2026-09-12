import SwiftUI

struct StatsBarView: View {
    let coins: Int
    let collected: Int
    var maximum = PopulationConfiguration.standard.uniqueCombinationCount

    var body: some View {
        HStack(spacing: 6) {
            CoinLabel(amount: coins)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Coins: \(coins)")
                .accessibilityIdentifier("coinCount")
            Spacer()
            Text("\(collected) of \(maximum) collected")
                .monospacedDigit()
                .accessibilityIdentifier("collectionCount")
        }
        .font(.system(.caption, design: .default, weight: .semibold))
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
    }
}
