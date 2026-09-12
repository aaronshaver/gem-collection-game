import CoreGraphics

/// Transient presentation state. Rejected drags never mutate the saved board.
struct BoardDrag: Equatable {
    let source: Int
    let touchStartOffset: CGSize
    private(set) var target: Int?
    private(set) var sourceOffset = CGSize.zero
    private(set) var targetOffset = CGSize.zero
    private(set) var thresholdReached = false
    private var direction = CGSize.zero

    init(source: Int, touchStartOffset: CGSize = .zero) {
        self.source = source
        self.touchStartOffset = touchStartOffset
    }

    mutating func update(translation: CGSize, cellSize: CGFloat) {
        guard !thresholdReached, cellSize > 0 else { return }
        if direction == .zero {
            guard max(abs(translation.width), abs(translation.height)) > cellSize * 0.10 else { return }
            if abs(translation.width) >= abs(translation.height) {
                direction.width = translation.width > 0 ? 1 : -1
            } else {
                direction.height = translation.height > 0 ? 1 : -1
            }
            let row = source / BoardLayout.columns + Int(direction.height)
            let column = source % BoardLayout.columns + Int(direction.width)
            if (0..<BoardLayout.rows).contains(row), (0..<BoardLayout.columns).contains(column) {
                target = row * BoardLayout.columns + column
            }
        }
        let distance = max(0, translation.width * direction.width + translation.height * direction.height)
        let progress = min(distance / cellSize, 1)
        let travel = target == nil ? cellSize * 0.18 * progress : min(distance, cellSize)
        sourceOffset = CGSize(width: direction.width * travel, height: direction.height * travel)
        // Ease into the neighbor's pull once the drag is 38% across the cell.
        let tension = max(0, (progress - 0.38) / 0.62)
        let pull = tension * tension * (3 - 2 * tension) * cellSize * 0.30
        targetOffset = target == nil ? .zero : CGSize(width: -direction.width * pull,
                                                      height: -direction.height * pull)
        // Neighbor starts half a cell from our center; enter another 20% to commit.
        // Include the initial grab position so this follows the finger, not the tile center.
        let fingerX = touchStartOffset.width + translation.width
        let fingerY = touchStartOffset.height + translation.height
        let fingerProgress = fingerX * direction.width + fingerY * direction.height
        let crossAxis = abs(fingerX * direction.height + fingerY * direction.width)
        if target != nil, fingerProgress >= cellSize * 0.70, crossAxis <= cellSize * 0.50 {
            thresholdReached = true
        }
    }

    mutating func returnHome() {
        sourceOffset = .zero
        targetOffset = .zero
    }
}
