import SwiftUI

struct DayLabel: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "d.square.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.06, green: 0.18, blue: 0.30),
                                 Color(red: 0.42, green: 0.70, blue: 0.94))
                .accessibilityHidden(true)
            Text("\(amount)").monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Days: \(amount)")
    }
}
