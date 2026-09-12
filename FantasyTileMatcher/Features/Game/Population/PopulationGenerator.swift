import GameplayKit

struct PopulationGenerator {
    func generate(seed: UInt64, count: Int, startingID: Int = 0) -> [Tile] {
        let random = GKMersenneTwisterRandomSource(seed: seed)
        return (0..<count).map { index in
            Tile(id: startingID + index, adventurer: Adventurer(
                race: Race.allCases[random.nextInt(upperBound: Race.allCases.count)],
                adventurerClass: AdventurerClass.allCases[random.nextInt(upperBound: AdventurerClass.allCases.count)],
                ability: Ability.allCases[random.nextInt(upperBound: Ability.allCases.count)],
                origin: Origin.allCases[random.nextInt(upperBound: Origin.allCases.count)]))
        }
    }

    /// All attributes use equal chances. Only initial boards are rerolled to avoid free starting matches.
    func freshField(seed: UInt64, startingID: Int = 0) -> [Tile] {
        var candidateSeed = seed
        while true {
            let pieces = generate(seed: candidateSeed, count: BoardLayout.cellCount, startingID: startingID)
            if !MatchRules.hasMatch(in: pieces) { return pieces }
            candidateSeed &+= 1
        }
    }
}
