import SwiftUI

struct MatchBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.title, weight: .semibold))
            .foregroundStyle(Color(white: 0.85))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, minHeight: 112)
            .background(.black, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16)
            .accessibilityIdentifier("matchBanner")
    }
}
