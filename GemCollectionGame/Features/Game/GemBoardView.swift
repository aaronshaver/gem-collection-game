import SwiftUI

struct GemBoardView: View {
    let pieces: [BoardPiece]
    let onSwap: (Int, Int) -> Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: BoardDrag?
    @GestureState private var isTouching = false

    private var returnAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.30, dampingFraction: 0.60)
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout(availableSize: geometry.size)
            ZStack {
                ForEach(pieces) { piece in
                    let index = pieces.firstIndex(where: { $0.id == piece.id })!
                    rockCell(index: index, layout: layout)
                }
            }
            .frame(width: layout.width, height: layout.height)
            .coordinateSpace(name: "rockBoard")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: geometry.size) { _ in drag = nil }
        }
        .onChange(of: isTouching) { touching in
            // Also recover if iOS cancels the gesture (e.g. an interruption).
            if !touching { finishDrag() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game board, 5 columns, 9 rows, 45 rocks and gems")
        .accessibilityIdentifier("gemBoard")
    }

    private func rockCell(index: Int, layout: BoardLayout) -> some View {
        let row = index / BoardLayout.columns
        let column = index % BoardLayout.columns
        let label = "\(pieces[index].label), row \(row + 1), column \(column + 1)"
        let lifted = drag?.source == index && drag?.thresholdReached == false
        let scale: CGFloat = lifted && !reduceMotion ? 1.07 : 1
        let layer: Double = drag?.source == index ? 2 : (drag?.target == index ? 1 : 0)
        return pieceArtwork(pieces[index])
            .frame(width: layout.gemDiameter, height: layout.gemDiameter)
            .scaleEffect(scale)
            .frame(width: layout.cellSize, height: layout.cellSize)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(false)
            .accessibilityLabel(label)
            .accessibilityHint("Drag to form a line of three matching colors. Other swaps spring back.")
            .accessibilityIdentifier("\(pieces[index].isRock ? "rock" : "gem")-\(index)")
            .offset(offset(for: index))
            .position(x: (CGFloat(column) + 0.5) * layout.cellSize,
                      y: (CGFloat(row) + 0.5) * layout.cellSize)
            .zIndex(layer)
            .gesture(rockGesture(index: index, cellSize: layout.cellSize))
    }

    @ViewBuilder
    private func pieceArtwork(_ piece: BoardPiece) -> some View {
        switch piece {
        case .rock(let rock): RockView(rock: rock)
        case .gem(let gem): GemView(gem: gem)
        }
    }

    private func rockGesture(index: Int, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("rockBoard"))
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { value in updateDrag(index: index, translation: value.translation, startLocation: value.startLocation, cellSize: cellSize) }
            .onEnded { _ in finishDrag() }
    }

    private func updateDrag(index: Int, translation: CGSize, startLocation: CGPoint, cellSize: CGFloat) {
        if drag == nil {
            let centerX = (CGFloat(index % BoardLayout.columns) + 0.5) * cellSize
            let centerY = (CGFloat(index / BoardLayout.columns) + 0.5) * cellSize
            let grabOffset = CGSize(width: startLocation.x - centerX, height: startLocation.y - centerY)
            withAnimation(.easeOut(duration: 0.10)) {
                drag = BoardDrag(source: index, touchStartOffset: grabOffset)
            }
        }
        guard var current = drag, current.source == index, !current.thresholdReached else { return }
        current.update(translation: translation, cellSize: cellSize)
        drag = current
        if current.thresholdReached {
            withAnimation(returnAnimation) {
                if let target = current.target { _ = onSwap(index, target) }
                drag?.returnHome()
            }
        }
    }

    private func offset(for index: Int) -> CGSize {
        guard let drag else { return .zero }
        if drag.source == index { return drag.sourceOffset }
        if drag.target == index { return drag.targetOffset }
        return .zero
    }

    private func finishDrag() {
        withAnimation(returnAnimation) { drag = nil }
    }
}
