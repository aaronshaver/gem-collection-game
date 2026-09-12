import SwiftUI

struct StashView: View {
    let stash: GemStash
    let choosingGem: Bool
    let isResolving: Bool
    let coins: Int
    let onClose: () -> Void
    let onAdd: () -> Void
    let onPut: () -> Void
    let onChoose: (Int) -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "archivebox.fill").foregroundStyle(.mint)
                Text("Stash").font(.title2.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close stash")
            }
            VStack(spacing: 10) {
                Button(action: onAdd) {
                    actionLabel("Add Gem to Stash", symbol: "plus.diamond")
                }
                .accessibilityLabel("Add Gem to Stash")
                .accessibilityValue("Costs \(GameBoard.stashCost) coins")
                .disabled(!stash.hasFreeSlot || isResolving || choosingGem || coins < GameBoard.stashCost)
                Button(action: onPut) {
                    actionLabel("Put Gem on Board", symbol: "arrow.up.forward.square")
                }
                .accessibilityLabel("Put Gem on Board")
                .accessibilityValue("Costs \(GameBoard.stashCost) coins")
                .disabled(stash.isEmpty || isResolving || choosingGem || coins < GameBoard.stashCost)
            }
            .buttonStyle(.bordered)
            .tint(.mint)
            Text(choosingGem ? "\(GameBoard.stashCost) coins paid · Close to refund" : "Each transfer costs \(GameBoard.stashCost) coins. Cancel to refund.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text(
                    choosingGem
                        ? "Choose a gem to place on the board" : "\(stash.slots.compactMap { $0 }.count) / \(stash.slots.count) slots filled"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Spacer()
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 14)], spacing: 14) {
                    ForEach(stash.slots.indices, id: \.self) { index in
                        Button {
                            onChoose(index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.06))
                                if let gem = stash.slots[index] {
                                    GemView(gem: gem, animateSparkles: false)
                                        .frame(width: 70, height: 70)
                                } else {
                                    Image(systemName: "plus").foregroundStyle(.white.opacity(0.25))
                                }
                            }
                            .frame(height: 104)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        choosingGem && stash.slots[index] != nil ? Color.mint : .white.opacity(0.12),
                                        lineWidth: 1.5)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!choosingGem || stash.slots[index] == nil || isResolving)
                        .accessibilityLabel(stash.slots[index].map { BoardPiece.gem($0).label } ?? "Empty stash slot")
                        .accessibilityIdentifier("stash-slot-\(index)")
                    }
                }
            }
        }
        .padding(20)
        .background(GameBackground())
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityIdentifier("stashDrawer")
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer(minLength: 8)
            CoinLabel(amount: GameBoard.stashCost)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
    }
}
