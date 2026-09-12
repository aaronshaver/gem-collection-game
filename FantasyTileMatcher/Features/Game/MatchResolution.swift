struct MatchBatch {
    let lines: [[Int]]
    var indices: Set<Int> { Set(lines.flatMap { $0 }) }
    let rewards: [MatchReward]
    /// Each tile is paid once, at its strongest qualifying run (including intersecting runs).
    var gold: Int {
        var perTile: [Int: Int] = [:]
        for reward in rewards {
            for index in reward.indices { perTile[index] = max(perTile[index] ?? 0, reward.goldPerTile) }
        }
        return perTile.values.reduce(0, +)
    }
}

struct GravityResult {
    let pieces: [Tile]
    let spawnRows: [Int: Int]
}

enum MatchResolution {
    static func scan(_ pieces: [Tile], columns: Int = BoardLayout.columns) -> MatchBatch {
        guard columns > 0 else { return MatchBatch(lines: [], rewards: []) }
        let values = pieces.map { $0.adventurer.values }
        var lines: [[Int]] = []
        var seen = Set<[Int]>()
        // Scan every attribute subset so a stronger trio inside a longer partial run earns its full reward.
        for mask in 1..<16 where mask.nonzeroBitCount >= 2 {
            func same(_ a: Int, _ b: Int) -> Bool {
                (0..<4).allSatisfy { mask & (1 << $0) == 0 || values[a][$0] == values[b][$0] }
            }
            for index in pieces.indices {
                for vertical in [false, true] {
                    let step = vertical ? columns : 1
                    let previous = index - step
                    if previous >= 0, vertical || previous / columns == index / columns, same(previous, index) { continue }
                    var line = [index]
                    var next = index + step
                    while next < pieces.count, vertical || next / columns == index / columns, same(index, next) {
                        line.append(next)
                        next += step
                    }
                    if line.count >= 3, seen.insert(line).inserted { lines.append(line) }
                }
            }
        }
        return MatchBatch(lines: lines, rewards: lines.map { MatchReward(indices: $0, pieces: pieces) })
    }

    static func collapse(_ pieces: [Tile], removing: Set<Int>, replacements: [Tile],
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
            for (offset, piece) in survivors.enumerated() { result[(vacancies + offset) * columns + column] = piece }
        }
        return GravityResult(pieces: result, spawnRows: spawnRows)
    }
}
