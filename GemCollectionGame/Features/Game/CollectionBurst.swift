import SwiftUI

struct CollectionBurst: View {
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.9), lineWidth: expanded ? 1 : 4)
                    .scaleEffect(expanded ? 1.45 : 0.35)
                Circle()
                    .fill(.white.opacity(0.75))
                    .scaleEffect(expanded ? 0.15 : 0.8)
                if !reduceMotion {
                    ForEach(0..<10) { index in
                        let angle = Double(index) * .pi * 2 / 10
                        Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "diamond.fill")
                            .font(.system(size: index.isMultiple(of: 3) ? 13 : 6))
                            .foregroundStyle(index.isMultiple(of: 2) ? .white : tint)
                            .offset(x: expanded ? cos(angle) * size * 0.8 : 0,
                                    y: expanded ? sin(angle) * size * 0.8 : 0)
                            .rotationEffect(.degrees(expanded ? Double(index * 27) : 0))
                    }
                }
            }
            .frame(width: size, height: size)
            .opacity(expanded ? 0 : 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.20 : 0.36)) { expanded = true }
        }
    }
}
