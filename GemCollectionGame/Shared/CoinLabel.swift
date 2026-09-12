import SwiftUI

struct CoinLabel: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text("\(amount)").monospacedDigit()
        }
    }
}
