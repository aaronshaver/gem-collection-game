import Foundation

extension Attribute {
    var title: String {
        switch self {
        case .race: return "Races"
        case .adventurerClass: return "Classes"
        case .ability: return "Abilities"
        case .origin: return "Origins"
        }
    }

    var names: [String] {
        switch self {
        case .race: return Race.allCases.map(\.rawValue)
        case .adventurerClass: return AdventurerClass.allCases.map(\.rawValue)
        case .ability: return Ability.allCases.map(\.rawValue)
        case .origin: return Origin.allCases.map(\.rawValue)
        }
    }

    func value(in adventurer: Adventurer) -> String {
        switch self {
        case .race: return adventurer.race.rawValue
        case .adventurerClass: return adventurer.adventurerClass.rawValue
        case .ability: return adventurer.ability.rawValue
        case .origin: return adventurer.origin.rawValue
        }
    }
}

struct QuestProgress: Identifiable {
    let attribute: Attribute
    let name: String
    let completed: Int
    let total: Int
    var id: String { "\(attribute.rawValue)-\(name)" }
    var fraction: Double { Double(completed) / Double(total) }
}

extension QuestCollection {
    func progress(for attribute: Attribute) -> [QuestProgress] {
        let counts = Dictionary(grouping: completed, by: { attribute.value(in: $0) }).mapValues(\.count)
        let total = Adventurer.all.count / attribute.names.count
        return attribute.names.map {
            QuestProgress(attribute: attribute, name: $0, completed: counts[$0, default: 0], total: total)
        }
    }
}
