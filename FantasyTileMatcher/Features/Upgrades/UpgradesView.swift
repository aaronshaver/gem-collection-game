import SwiftUI

struct UpgradesView: View {
    @ObservedObject var board: GameBoard
    let onTravel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Upgrades").font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Upgrades")
            }
            Button(action: onTravel) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Travel to another town nearby")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Refreshes board randomly")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 20) {
                        CoinLabel(amount: GameBoard.travelGoldCost)
                        DayLabel(amount: GameBoard.travelDayCost)
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(GameTheme.accent.opacity(0.35), lineWidth: 1)
                }
                .opacity(board.canTravel ? 1 : 0.45)
            }
            .buttonStyle(.plain)
            .disabled(!board.canTravel)
            .accessibilityLabel("Travel to another town nearby")
            .accessibilityValue("Costs 2 gold and takes 1 day")
            .accessibilityHint("Refreshes board randomly")
            .accessibilityIdentifier("travelToTown")
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(GameBackground())
        .tint(GameTheme.accent)
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .accessibilityIdentifier("upgradesScreen")
    }
}
