import SwiftUI

struct GemBoardView: View {
    let rocks: [Rock]

    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout(availableSize: geometry.size)
            VStack(spacing: 0) {
                ForEach(0..<BoardLayout.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<BoardLayout.columns, id: \.self) { column in
                            RockView(rock: rocks[row * BoardLayout.columns + column])
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
        .accessibilityLabel("Game board, 5 columns, 9 rows, 45 gray rocks")
        .accessibilityIdentifier("gemBoard")
    }
}
