import CoreGraphics

/// Fixed-size square tiles, with the remaining space shared equally between tiles and edges.
struct BoardLayout {
    static let columns = 3
    static let rows = 5
    static let cellCount = columns * rows
    static let tileSide: CGFloat = 128

    let width: CGFloat
    let height: CGFloat
    var tileSize: CGFloat { Self.tileSide }
    let gap: CGSize

    init(availableSize: CGSize) {
        width = max(Self.tileSide * CGFloat(Self.columns), availableSize.width)
        height = max(Self.tileSide * CGFloat(Self.rows), availableSize.height)
        gap = CGSize(width: (width - Self.tileSide * CGFloat(Self.columns)) / CGFloat(Self.columns + 1),
                     height: (height - Self.tileSide * CGFloat(Self.rows)) / CGFloat(Self.rows + 1))
    }

    var spacing: CGSize { CGSize(width: tileSize + gap.width, height: tileSize + gap.height) }

    func center(at index: Int) -> CGPoint {
        CGPoint(x: gap.width + tileSize / 2 + CGFloat(index % Self.columns) * spacing.width,
                y: gap.height + tileSize / 2 + CGFloat(index / Self.columns) * spacing.height)
    }
}
