enum SwapRules {
    static func canSwap(_ source: Int, _ target: Int, in pieces: [Tile], columns: Int = BoardLayout.columns) -> Bool {
        columns > 0 && pieces.indices.contains(source) && pieces.indices.contains(target) &&
        abs(source / columns - target / columns) + abs(source % columns - target % columns) == 1
    }
}
