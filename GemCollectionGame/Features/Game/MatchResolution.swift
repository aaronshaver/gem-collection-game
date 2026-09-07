struct MatchBatch {
    let lines: [[Int]]
    var indices: Set<Int> { Set(lines.flatMap { $0 }) }
    var coins: Int { indices.count }
}

struct GravityResult {
    let pieces: [BoardPiece]
    /// New pieces begin in negative rows above their column.
    let spawnRows: [Int: Int]
}

enum MatchResolution {
    static func scan(_ pieces: [BoardPiece], columns: Int = BoardLayout.columns) -> MatchBatch {
        guard columns > 0 else { return MatchBatch(lines: []) }
        var lines: [[Int]] = []
        for index in pieces.indices {
            guard let color = MatchRules.color(of: pieces[index]) else { continue }
            for step in [1, columns] {
                let previous = index - step
                let samePrevious = previous >= 0 && (step != 1 || previous / columns == index / columns) &&
                    MatchRules.color(of: pieces[previous]) == color
                if samePrevious { continue }
                var line = [index]
                var next = index + step
                while next < pieces.count, step != 1 || next / columns == index / columns,
                      MatchRules.color(of: pieces[next]) == color {
                    line.append(next)
                    next += step
                }
                if line.count >= 3 { lines.append(line) }
            }
        }
        return MatchBatch(lines: lines)
    }

    static func collapse(_ pieces: [BoardPiece], removing: Set<Int>, replacements: [BoardPiece],
                         columns: Int = BoardLayout.columns) -> GravityResult {
        precondition(columns > 0 && pieces.count % columns == 0)
        precondition(removing.allSatisfy { pieces.indices.contains($0) } && replacements.count == removing.count)
        let rows = pieces.count / columns
        var result = pieces
        var spawnRows: [Int: Int] = [:]
        var replacementIndex = 0
        for column in 0..<columns {
            let survivors = (0..<rows).map { $0 * columns + column }.filter { !removing.contains($0) }.map { pieces[$0] }
            let vacancies = rows - survivors.count
            for row in 0..<vacancies {
                let piece = replacements[replacementIndex]
                replacementIndex += 1
                result[row * columns + column] = piece
                spawnRows[piece.id] = row - vacancies
            }
            for (offset, piece) in survivors.enumerated() {
                result[(vacancies + offset) * columns + column] = piece
            }
        }
        return GravityResult(pieces: result, spawnRows: spawnRows)
    }
}
