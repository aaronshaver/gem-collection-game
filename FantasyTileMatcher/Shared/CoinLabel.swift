import SwiftUI

struct CoinLabel: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "g.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.35, green: 0.20, blue: 0.02), .yellow)
                .accessibilityHidden(true)
            Text("\(amount)").monospacedDigit()
        }
    }
}
