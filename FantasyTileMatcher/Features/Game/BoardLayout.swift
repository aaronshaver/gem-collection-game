import CoreGraphics

/// Square tiles fill the board, with equal edge and inter-tile gaps on each axis.
struct BoardLayout {
    static let columns = 3
    static let rows = 5
    static let cellCount = columns * rows

    let width: CGFloat
    let height: CGFloat
    let tileSize: CGFloat
    let gap: CGSize

    init(availableSize: CGSize) {
        width = max(0, availableSize.width)
        height = max(0, availableSize.height)
        let minimumGap: CGFloat = 12
        tileSize = max(0, min((width - minimumGap * CGFloat(Self.columns + 1)) / CGFloat(Self.columns),
                              (height - minimumGap * CGFloat(Self.rows + 1)) / CGFloat(Self.rows)))
        gap = CGSize(width: (width - tileSize * CGFloat(Self.columns)) / CGFloat(Self.columns + 1),
                     height: (height - tileSize * CGFloat(Self.rows)) / CGFloat(Self.rows + 1))
    }

    var spacing: CGSize { CGSize(width: tileSize + gap.width, height: tileSize + gap.height) }

    func center(at index: Int) -> CGPoint {
        CGPoint(x: gap.width + tileSize / 2 + CGFloat(index % Self.columns) * spacing.width,
                y: gap.height + tileSize / 2 + CGFloat(index / Self.columns) * spacing.height)
    }
}
