import SwiftUI

struct TileBoardView: View {
    let pieces: [Tile]
    let collectedIDs: Set<Int>
    let spawnRows: [Int: Int]
    let isResolving: Bool
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
                    tileCell(index: index, layout: layout)
                }
            }
            .frame(width: layout.width, height: layout.height)
            .coordinateSpace(name: "tileBoard")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: geometry.size) { _ in drag = nil }
        }
        .onChange(of: isTouching) { touching in
            // Also recover if iOS cancels the gesture (e.g. an interruption).
            if !touching { finishDrag() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game board, 3 columns, 5 rows, 15 adventurer tiles")
        .accessibilityIdentifier("tileBoard")
    }

    private func tileCell(index: Int, layout: BoardLayout) -> some View {
        let row = index / BoardLayout.columns
        let column = index % BoardLayout.columns
        let label = "\(pieces[index].label), row \(row + 1), column \(column + 1)"
        let collected = collectedIDs.contains(pieces[index].id)
        let lifted = drag?.source == index && drag?.thresholdReached == false
        let scale: CGFloat = lifted && !reduceMotion ? 1.07 : 1
        let layer: Double = drag?.source == index ? 2 : (drag?.target == index ? 1 : 0)
        return ZStack {
            if collected {
                CollectionBurst(adventurer: pieces[index].adventurer)
            } else {
                TileView(adventurer: pieces[index].adventurer).scaleEffect(scale)
            }
        }
            .frame(width: layout.tileSize, height: layout.tileSize)
            .frame(width: layout.cellSize, height: layout.cellSize)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(false)
            .accessibilityLabel(label)
            .accessibilityHint("Swap with any adjacent tile. Lines of three or more sharing at least two attributes clear.")
            .accessibilityAction(named: Text("Swap left")) { _ = onSwap(index, column > 0 ? index - 1 : -1) }
            .accessibilityAction(named: Text("Swap right")) { _ = onSwap(index, column < BoardLayout.columns - 1 ? index + 1 : -1) }
            .accessibilityAction(named: Text("Swap up")) { _ = onSwap(index, index - BoardLayout.columns) }
            .accessibilityAction(named: Text("Swap down")) { _ = onSwap(index, index + BoardLayout.columns) }
            .accessibilityIdentifier("tile-\(index)")
            .offset(offset(for: index))
            .offset(y: CGFloat((spawnRows[pieces[index].id] ?? row) - row) * layout.cellSize)
            .position(x: (CGFloat(column) + 0.5) * layout.cellSize,
                      y: (CGFloat(row) + 0.5) * layout.cellSize)
            .zIndex(collected ? 3 : layer)
            .gesture(tileGesture(index: index, cellSize: layout.cellSize))
            .allowsHitTesting(!isResolving)
    }

    private func tileGesture(index: Int, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("tileBoard"))
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { value in
                updateDrag(index: index, translation: value.translation, startLocation: value.startLocation, cellSize: cellSize)
            }
            .onEnded { value in
                finishDrag()
            }
    }

    private func updateDrag(index: Int, translation: CGSize, startLocation: CGPoint, cellSize: CGFloat) {
        guard !isResolving else { return }
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
