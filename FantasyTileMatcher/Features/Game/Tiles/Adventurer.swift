import Foundation

// Declaration order is also the quadrant order: top left, top right, bottom left, bottom right.
enum Attribute: Int, CaseIterable { case race, adventurerClass, ability, origin }
enum Race: String, Codable, CaseIterable, Identifiable {
    case cat = "Cat", dwarf = "Dwarf", elf = "Elf", fairy = "Fairy"
    case goblin = "Goblin", human = "Human", lizard = "Lizard", orc = "Orc"
    var id: String { rawValue }
}
enum AdventurerClass: String, Codable, CaseIterable {
    case acrobat = "Acrobat", brute = "Brute", druid = "Druid", healer = "Healer"
    case leader = "Leader", pugilist = "Pugilist", rogue = "Rogue", scholar = "Scholar"
    case traveler = "Traveler", wizard = "Wizard"
}
enum Ability: String, Codable, CaseIterable {
    case charisma = "Charisma", dexterity = "Dexterity", endurance = "Endurance"
    case intelligence = "Intelligence", strength = "Strength", wisdom = "Wisdom"
}
enum Origin: String, Codable, CaseIterable {
    case coast = "Coast", desert = "Desert", forest = "Forest", grassland = "Grassland"
    case ice = "Ice", mountains = "Mountains", swamp = "Swamp"
}

struct Adventurer: Codable, Hashable, Identifiable {
    let race: Race
    let adventurerClass: AdventurerClass
    let ability: Ability
    let origin: Origin
    var id: String { values.joined(separator: "-") }
    var values: [String] { [race.rawValue, adventurerClass.rawValue, ability.rawValue, origin.rawValue] }
    var label: String { values.joined(separator: ", ") }
    static let combinationsPerRace = AdventurerClass.allCases.count * Ability.allCases.count * Origin.allCases.count
    static let all: [Adventurer] = Race.allCases.flatMap { race in
        AdventurerClass.allCases.flatMap { job in
            Ability.allCases.flatMap { ability in
                Origin.allCases.map { Adventurer(race: race, adventurerClass: job, ability: ability, origin: $0) }
            }
        }
    }
}

struct Tile: Codable, Equatable, Identifiable {
    let id: Int
    let adventurer: Adventurer
    var label: String { adventurer.label }
}
