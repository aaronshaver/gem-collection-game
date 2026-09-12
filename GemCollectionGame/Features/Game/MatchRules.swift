/// Color alone determines matches; grade and polygon shape do not matter.
enum MatchRules {
    /// Contiguous runs that qualify for a color/grade/shape collection entry.
    static func exactRuns(in line: [Int], pieces: [BoardPiece]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        var previous: GemCombination?
        for index in line {
            let combination: GemCombination?
            if pieces.indices.contains(index), case .gem(let gem) = pieces[index] {
                combination = GemCombination(gem)
            } else {
                combination = nil
            }
            if combination == nil || combination != previous {
                if current.count >= 3 { runs.append(current) }
                current = []
            }
            if combination != nil { current.append(index) }
            previous = combination
        }
        if current.count >= 3 { runs.append(current) }
        return runs
    }

    static func color(of piece: BoardPiece) -> String? {
        if case .gem(let gem) = piece { return gem.color.id }
        return nil
    }

    static func hasMatch(in pieces: [BoardPiece], columns: Int = BoardLayout.columns) -> Bool {
        pieces.indices.contains { matches(at: $0, in: pieces, columns: columns) }
    }

    static func matches(at index: Int, in pieces: [BoardPiece], columns: Int = BoardLayout.columns) -> Bool {
        guard columns > 0, pieces.indices.contains(index), let color = color(of: pieces[index]) else { return false }
        let row = index / columns, column = index % columns
        func run(dx: Int, dy: Int) -> Int {
            var x = column + dx, y = row + dy, count = 0
            while x >= 0, x < columns, y >= 0 {
                let position = y * columns + x
                guard pieces.indices.contains(position), Self.color(of: pieces[position]) == color else { break }
                count += 1
                x += dx
                y += dy
            }
            return count
        }
        return 1 + run(dx: -1, dy: 0) + run(dx: 1, dy: 0) >= 3 ||
               1 + run(dx: 0, dy: -1) + run(dx: 0, dy: 1) >= 3
    }
}
