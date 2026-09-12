import SwiftUI

struct QuestProgressRow: View {
    let progress: QuestProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HStack(spacing: 12) {
            Text(progress.name)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            ProgressView(value: progress.fraction)
                .tint(.mint)
                .overlay {
                    if progress.total > 0 && progress.completed == progress.total {
                        if reduceMotion || scenePhase != .active {
                            Capsule().fill(.mint)
                                .frame(height: 4)
                                .shadow(color: .mint.opacity(0.8), radius: 5)
                        } else {
                            CompletedQuestGlow()
                        }
                    }
                }
            Text("\(progress.completed) of \(progress.total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progress.name)
        .accessibilityValue("\(progress.completed) of \(progress.total) Quests, \(Int(progress.fraction * 100)) percent")
    }
}

private struct CompletedQuestGlow: View {
    @State private var bright = false

    var body: some View {
        Capsule().fill(.mint)
            .frame(height: 4)
            .shadow(color: .mint.opacity(bright ? 0.95 : 0.35), radius: bright ? 9 : 3)
            .shadow(color: .mint.opacity(bright ? 0.6 : 0.15), radius: bright ? 4 : 1)
            .scaleEffect(x: 1, y: bright ? 1.5 : 1)
            .task {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    bright = true
                }
            }
    }
}
