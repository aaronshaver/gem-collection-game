import SwiftUI

struct MarketView: View {
    @ObservedObject var board: GameBoard
    let onTravel: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "g.circle.fill")
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.mint)
                    .frame(width: 44, height: 44)
                Spacer()
                Text("Market")
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Market")
            }
            .font(.system(size: 20, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            ScrollView {
                travelItem.padding(20)
            }
        }
        .background(GameBackground())
        .accessibilityIdentifier("marketScreen")
    }

    private var travelItem: some View {
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
    }
}
