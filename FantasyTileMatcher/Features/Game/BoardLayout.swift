import CoreGraphics

/// Square cells keep the entire board visible in the available safe-area space.
struct BoardLayout {
    static let columns = 3
    static let rows = 5
    static let cellCount = columns * rows

    let cellSize: CGFloat

    init(availableSize: CGSize) {
        cellSize = max(0, min(availableSize.width / CGFloat(Self.columns),
                              availableSize.height / CGFloat(Self.rows)))
    }

    var width: CGFloat { cellSize * CGFloat(Self.columns) }
    var height: CGFloat { cellSize * CGFloat(Self.rows) }
    var tileSize: CGFloat { cellSize * 0.96 }
}
