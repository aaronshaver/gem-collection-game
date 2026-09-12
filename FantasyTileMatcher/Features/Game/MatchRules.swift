enum MatchRules {
    static func exactRuns(in line: [Int], pieces: [Tile]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for index in line {
            guard pieces.indices.contains(index) else { continue }
            if let previous = current.last, pieces[previous].adventurer != pieces[index].adventurer {
                if current.count >= 3 { runs.append(current) }
                current = []
            }
            current.append(index)
        }
        if current.count >= 3 { runs.append(current) }
        return runs
    }

    static func hasMatch(in pieces: [Tile], columns: Int = BoardLayout.columns) -> Bool {
        !MatchResolution.scan(pieces, columns: columns).lines.isEmpty
    }
}
