import SwiftUI

struct MatchBanner: View {
    let count: Int

    var body: some View {
        Text("\(count) matched: basic")
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityIdentifier("matchBanner")
    }
}
