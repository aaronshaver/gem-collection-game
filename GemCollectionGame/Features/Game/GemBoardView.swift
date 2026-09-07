import SwiftUI

struct GemBoardView: View {
    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout(availableSize: geometry.size)
            VStack(spacing: 0) {
                ForEach(0..<BoardLayout.rows, id: \.self) { _ in
                    HStack(spacing: 0) {
                        ForEach(0..<BoardLayout.columns, id: \.self) { _ in
                            Circle()
                                .fill(Color(white: 0.64).gradient)
                                .frame(width: layout.gemDiameter, height: layout.gemDiameter)
                                .frame(width: layout.cellSize, height: layout.cellSize)
                        }
                    }
                }
            }
            .frame(width: layout.width, height: layout.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Game board, 5 columns, 8 rows, 40 gray gems")
        .accessibilityIdentifier("gemBoard")
    }
}
