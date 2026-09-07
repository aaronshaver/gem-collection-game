enum SwapRules {
    static func canSwap(_ source: Int, _ target: Int, in pieces: [BoardPiece], columns: Int = BoardLayout.columns) -> Bool {
        guard columns > 0, pieces.indices.contains(source), pieces.indices.contains(target),
              abs(source / columns - target / columns) + abs(source % columns - target % columns) == 1,
              MatchRules.color(of: pieces[source]) != MatchRules.color(of: pieces[target]) else { return false }
        var swapped = pieces
        swapped.swapAt(source, target)
        return MatchRules.matches(at: source, in: swapped, columns: columns) ||
               MatchRules.matches(at: target, in: swapped, columns: columns)
    }
}
