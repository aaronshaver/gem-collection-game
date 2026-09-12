import SwiftUI

struct QuestProgressRow: View {
    let progress: QuestProgress

    var body: some View {
        HStack(spacing: 12) {
            Text(progress.name)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            ProgressView(value: progress.fraction)
                .tint(.mint)
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
