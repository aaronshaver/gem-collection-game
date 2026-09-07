import SwiftUI

struct SoilBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.13, green: 0.085, blue: 0.055),
                                Color(red: 0.065, green: 0.041, blue: 0.028)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Canvas { context, size in
                    // Fixed grain positions keep the soil stable across redraws.
                    for index in 0..<650 {
                        let x = Double((index * 137 + 31) % 997) / 997 * size.width
                        let y = Double((index * 293 + 71) % 991) / 991 * size.height
                        let diameter = Double(index % 3 + 1) * 0.6
                        let grain = Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter))
                        context.fill(grain, with: .color(index.isMultiple(of: 3)
                            ? .white.opacity(0.035) : .black.opacity(0.16)))
                    }
                }
            }
            .accessibilityHidden(true)
    }
}
