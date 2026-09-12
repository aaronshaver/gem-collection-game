struct MatchBatch {
    let lines: [[Int]]
    var indices: Set<Int> { Set(lines.flatMap { $0 }) }
    let rewards: [MatchReward]
    var coins: Int {
        var perGem: [Int: Int] = [:]
        for reward in rewards {
            for index in reward.indices {
                perGem[index] = max(perGem[index] ?? 0, reward.coinsPerGem)
            }
        }
        return perGem.values.reduce(0, +)
    }

    static func resolved(lines: [[Int]], pieces: [BoardPiece]) -> MatchBatch {
        guard lines.count > 1 else {
            return MatchBatch(lines: lines, rewards: lines.map { MatchReward(indices: $0, pieces: pieces) })
        }
        let all = Set(lines.flatMap { $0 })
        let exact = Set(lines.flatMap { MatchRules.exactRuns(in: $0, pieces: pieces).flatMap { $0 } })
        return MatchBatch(lines: lines, rewards: [
            MatchReward(indices: exact.sorted(), coinsPerGem: 8),
            MatchReward(indices: all.subtracting(exact).sorted(), coinsPerGem: 1)
        ])
    }
}

struct GravityResult {
    let pieces: [BoardPiece]
    /// New pieces begin in negative rows above their column.
    let spawnRows: [Int: Int]
}

enum MatchResolution {
    static func scan(_ pieces: [BoardPiece], columns: Int = BoardLayout.columns,
                     swapping: (Int, Int)? = nil, formedAfter previousPieces: [BoardPiece]? = nil) -> MatchBatch {
        guard columns > 0 else { return MatchBatch(lines: [], rewards: []) }
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
                if line.count >= 3, swapping.map({ line.contains($0.0) || line.contains($0.1) }) ?? true {
                    // Gravity must create a new line, not merely move an existing line intact.
                    if let previousPieces,
                       let start = previousPieces.firstIndex(where: { $0.id == pieces[line[0]].id }) {
                        let unchanged = line.enumerated().allSatisfy { offset, index in
                            let previous = start + offset * step
                            return previousPieces.indices.contains(previous) &&
                                (step != 1 || previous / columns == start / columns) &&
                                previousPieces[previous].id == pieces[index].id
                        }
                        if unchanged { continue }
                    }
                    lines.append(line)
                }
            }
        }
        // The dragged gem's destination wins over a match made by the displaced piece.
        // If dragging a rock (or the moved gem makes no line), use the other endpoint.
        if let (_, target) = swapping {
            let destinationLines = lines.filter { $0.contains(target) }
            if !destinationLines.isEmpty { lines = destinationLines }
        }
        // Gesture direction breaks intersection ambiguity; it must not reject a sole valid line.
        let preferred: [[Int]] = swapping.map { source, target in
            let step = source / columns == target / columns ? columns : 1
            return lines.filter { $0[1] - $0[0] == step }
        } ?? []
        let candidates = preferred.isEmpty ? lines : preferred
        // Keep the existing gesture/board-order choice unless an exact set crosses both axes.
        let longest = candidates.reduce([Int]()) { $1.count > $0.count ? $1 : $0 }
        guard !longest.isEmpty else { return MatchBatch(lines: [], rewards: []) }
        let exact = Set(MatchRules.exactRuns(in: longest, pieces: pieces).flatMap { $0 })
        let crossing = lines.filter { line in
            guard line != longest, line[1] - line[0] != longest[1] - longest[0] else { return false }
            let otherExact = Set(MatchRules.exactRuns(in: line, pieces: pieces).flatMap { $0 })
            return !exact.isDisjoint(with: otherExact)
        }
        return .resolved(lines: [longest] + crossing, pieces: pieces)
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
