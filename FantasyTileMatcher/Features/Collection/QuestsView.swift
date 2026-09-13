import SwiftUI

struct QuestsView: View {
    let collection: QuestCollection
    let onClose: () -> Void
    @State private var selectedProgress: QuestProgress?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if selectedProgress != nil {
                    iconButton("chevron.left", label: "Back to Quests") { selectedProgress = nil }
                } else {
                    Image(systemName: "trophy.fill").foregroundStyle(.mint).frame(width: 44, height: 44)
                }
                Spacer()
                Text(selectedProgress?.name ?? "Quests")
                Spacer()
                iconButton("xmark", label: "Close Quests", action: onClose)
            }
            .font(.system(size: 20, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            ScrollView {
                if let progress = selectedProgress { variants(progress) } else { overview }
            }
        }
        .background(GameBackground())
        .accessibilityIdentifier("questsScreen")
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Current Quest").font(.headline).accessibilityAddTraits(.isHeader)
            if let quest = collection.current {
                HStack(spacing: 20) {
                    TileView(adventurer: quest).frame(width: BoardLayout.tileSide, height: BoardLayout.tileSide)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(quest.race.rawValue)
                        Text(quest.adventurerClass.rawValue)
                        Text(quest.ability.rawValue)
                        Text(quest.origin.rawValue)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Current Quest: \(quest.label)")
                .accessibilityIdentifier("currentQuest")
            } else {
                Text("None. All quests completed! You truly are amazing. The king and everyone in the kingdom thanks you for saving them from evil.").font(.title2.bold())
            }
            Divider().overlay(.white.opacity(0.08))
            Text("Completed Quests").font(.headline).accessibilityAddTraits(.isHeader)
            ForEach(Attribute.allCases, id: \.rawValue) { attribute in
                VStack(alignment: .leading, spacing: 10) {
                    Text(attribute.title).font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    LazyVStack(spacing: 6) {
                        ForEach(collection.progress(for: attribute)) { progress in
                            Button { selectedProgress = progress } label: {
                                QuestProgressRow(progress: progress)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("quest-progress-\(progress.id)")
                        }
                    }
                }
            }
        }.padding(20)
    }

    // Keep the existing drill-down's grouped trio/checkmark presentation with the new tile data.
    private func variants(_ progress: QuestProgress) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(Adventurer.all.filter { progress.attribute.value(in: $0) == progress.name }) { adventurer in
                let found = collection.completed.contains(adventurer)
                HStack {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { _ in TileView(adventurer: adventurer).frame(width: 70, height: 70) }
                    }
                    .opacity(found ? 1 : 0.4)
                    Spacer()
                    Image(systemName: found ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 25, weight: .light))
                        .foregroundStyle(found ? .green : .white.opacity(0.14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(adventurer.label)
                .accessibilityValue(found ? "Completed" : "Not completed")
            }
        }.padding(20)
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 44, height: 44).background(.white.opacity(0.08), in: Circle())
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
