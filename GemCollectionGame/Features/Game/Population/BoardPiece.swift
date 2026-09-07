import Foundation

enum BoardPiece: Codable, Equatable, Identifiable {
    case rock(Rock)
    case gem(Gem)

    var id: Int {
        switch self { case .rock(let rock): return rock.id; case .gem(let gem): return gem.id }
    }
    var isRock: Bool { if case .rock = self { return true }; return false }
    var label: String {
        switch self {
        case .rock: return "Rock"
        case .gem(let gem): return "\(gem.grade.name) \(gem.color.name.lowercased()) \(gem.shape.sides)-sided gem"
        }
    }
}
