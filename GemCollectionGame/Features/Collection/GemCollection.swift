import Foundation

/// Appearance identity deliberately excludes a gem's random seed and board ID.
struct GemCombination: Codable, Hashable, Identifiable {
    let colorID: String
    let gradeID: String
    let shapeID: String
    var id: String { "\(colorID)-\(gradeID)-\(shapeID)" }

    init(_ gem: Gem) {
        colorID = gem.color.id
        gradeID = gem.grade.id
        shapeID = gem.shape.id
    }

    func gem(in catalog: PopulationConfiguration) -> Gem? {
        guard let color = catalog.colors.first(where: { $0.id == colorID }),
              let grade = catalog.grades.first(where: { $0.id == gradeID }),
              let shape = catalog.shapes.first(where: { $0.id == shapeID }) else { return nil }
        return Gem(id: 0, seed: 42, grade: grade, color: color, shape: shape)
    }
}

struct GemCollection: Codable, Equatable {
    private(set) var discovered: Set<GemCombination> = []
    private(set) var recent: [GemCombination] = []
    private(set) var hasUnread = false

    mutating func record(_ combination: GemCombination) {
        guard discovered.insert(combination).inserted else { return }
        recent.insert(combination, at: 0)
        recent = Array(recent.prefix(2))
        hasUnread = true
    }

    /// Only contiguous exact runs in the line actually being removed qualify.
    mutating func record(lines: [[Int]], pieces: [BoardPiece]) {
        for line in lines {
            var previous: GemCombination?
            var count = 0
            for index in line {
                guard pieces.indices.contains(index), case .gem(let gem) = pieces[index] else {
                    previous = nil
                    count = 0
                    continue
                }
                let combination = GemCombination(gem)
                count = combination == previous ? count + 1 : 1
                previous = combination
                if count == 3 { record(combination) }
            }
        }
    }

    mutating func markRead() { hasUnread = false }
}
