import SwiftUI

struct CollectionView: View {
    let collection: GemCollection
    let onClose: () -> Void
    var catalog = PopulationConfiguration.standard
    @State private var selectedColor: GemColor?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if selectedColor != nil {
                    iconButton("chevron.left", label: "Back to collection") { selectedColor = nil }
                } else {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.mint)
                        .frame(width: 44, height: 44)
                        .accessibilityLabel("Collection")
                }
                Spacer()
                if let color = selectedColor, let gem = categoryGem(color) {
                    HStack(spacing: 8) {
                        artwork(gem, size: 44)
                        Text(color.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                Spacer()
                iconButton("xmark", label: "Close collection", action: onClose)
            }
            .font(.system(size: 20, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                if let color = selectedColor {
                    variants(color)
                } else {
                    overview
                }
            }
        }
        .background(GameBackground())
        .accessibilityIdentifier("collectionScreen")
    }

    private var overview: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Recently Collected")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            HStack(spacing: 16) {
                ForEach(0..<2) { index in
                    Group {
                        if collection.recent.indices.contains(index),
                           let gem = collection.recent[index].gem(in: catalog) {
                            VStack(spacing: 10) {
                                artwork(gem, size: 90)
                                VStack(spacing: 3) {
                                    Text(gem.color.name)
                                        .font(.headline)
                                    Text(gem.grade.name)
                                    Text("\(gem.shape.sides)-sided")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 18)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(description(gem) + ", collected")
                        } else {
                            Image(systemName: "diamond")
                                .font(.system(size: 44, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.18))
                                .accessibilityLabel("No recent discovery")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 216)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 24))
                }
            }
            Divider().overlay(.white.opacity(0.08))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 14)], spacing: 14) {
                ForEach(catalog.colors) { color in
                    if let gem = categoryGem(color) {
                        Button { selectedColor = color } label: {
                            artwork(gem, size: 70)
                                .frame(maxWidth: .infinity)
                                .frame(height: 104)
                                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.name + " collection")
                        .accessibilityIdentifier("collection-color-\(color.id)")
                    }
                }
            }
        }
        .padding(20)
    }

    private func variants(_ color: GemColor) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(catalog.shapes.sorted { $0.sides < $1.sides }) { shape in
                VStack(spacing: 2) {
                    ForEach(catalog.grades) { grade in
                        let gem = Gem(id: 0, seed: 42, grade: grade, color: color, shape: shape)
                        let found = collection.discovered.contains(GemCombination(gem))
                        HStack {
                            HStack(spacing: 8) {
                                ForEach(0..<3) { _ in
                                    artwork(gem, size: 60)
                                }
                            }
                            .saturation(found ? 1 : 0.3)
                            .opacity(found ? 1 : 0.4)
                            Spacer()
                            if found { checkmark } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 25, weight: .light))
                                    .foregroundStyle(.white.opacity(0.14))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(description(gem))
                        .accessibilityValue(found ? "Collected" : "Not collected")
                        .accessibilityIdentifier("collection-entry-\(GemCombination(gem).id)")
                    }
                }
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
            }
        }.padding(20)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 25, weight: .semibold))
            .foregroundStyle(.green)
    }

    private func artwork(_ gem: Gem, size: CGFloat) -> some View {
        GemView(gem: gem, animateSparkles: false, showSideLabel: false)
            .frame(width: size, height: size)
    }

    private func categoryGem(_ color: GemColor) -> Gem? {
        guard let grade = catalog.grades.first(where: { $0.id == "dull" }),
              let shape = catalog.shapes.first(where: { $0.sides == 5 }) else { return nil }
        return Gem(id: 0, seed: 42, grade: grade, color: color, shape: shape)
    }

    private func description(_ gem: Gem) -> String {
        "\(gem.color.name), \(gem.grade.name), \(gem.shape.sides) sides"
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
