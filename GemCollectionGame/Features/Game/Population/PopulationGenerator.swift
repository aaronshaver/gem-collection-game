import Foundation
import GameplayKit

struct PopulationGenerator {
    enum ConfigurationError: Error { case invalidCatalog }
    let configuration: PopulationConfiguration
    private let grades: WeightedTable<GemGrade>
    private let colors: WeightedTable<GemColor>
    private let shapes: WeightedTable<GemShape>

    init(configuration: PopulationConfiguration) throws {
        guard configuration.gemProbability.isFinite, (0...1).contains(configuration.gemProbability),
              configuration.shapes.allSatisfy({ $0.sides >= 3 }),
              configuration.grades.allSatisfy({ $0.crackCount >= 0 && $0.sparkleCount >= 0 }),
              configuration.colors.allSatisfy({ color in
                  [color.red, color.green, color.blue].allSatisfy { $0.isFinite && (0...1).contains($0) }
              }),
              Set(configuration.grades.map(\.id)).count == configuration.grades.count,
              Set(configuration.colors.map(\.id)).count == configuration.colors.count,
              Set(configuration.shapes.map(\.id)).count == configuration.shapes.count
        else { throw ConfigurationError.invalidCatalog }
        self.configuration = configuration
        grades = try WeightedTable(configuration.grades.map { ($0, $0.weight) })
        colors = try WeightedTable(configuration.colors.map { ($0, $0.weight) })
        shapes = try WeightedTable(configuration.shapes.map { ($0, $0.weight) })
    }

    static func randomMenuGem() -> Gem {
        var configuration = PopulationConfiguration.standard
        configuration.gemProbability = 1
        configuration.grades = configuration.grades.filter { $0.id == "shiny" }
        configuration.shapes = configuration.shapes.filter { $0.sides == 5 }
        let generator = try! PopulationGenerator(configuration: configuration)
        guard case .gem(let gem) = generator.generate(seed: UInt64.random(in: .min ... .max), count: 1)[0] else {
            preconditionFailure("Gem-only generation must produce a gem")
        }
        return gem
    }

    func generate(seed: UInt64, count: Int, existingRocks: [Rock] = [], startingID: Int = 0) -> [BoardPiece] {
        let random = GKLinearCongruentialRandomSource(seed: seed)
        func unit() -> Double { Double(random.nextUniform()) }
        func objectSeed() -> UInt64 {
            UInt64(UInt32(truncatingIfNeeded: random.nextInt())) << 32 |
            UInt64(UInt32(truncatingIfNeeded: random.nextInt()))
        }
        return (0..<count).map { index in
            let isGem = unit() < configuration.gemProbability
            let seed = objectSeed()
            if isGem {
                return .gem(Gem(id: startingID + index, seed: seed, grade: grades.select(unit: unit()),
                                color: colors.select(unit: unit()), shape: shapes.select(unit: unit())))
            }
            if index < existingRocks.count, existingRocks[index].id == index {
                return .rock(existingRocks[index])
            }
            return .rock(Rock(id: startingID + index, seed: seed))
        }
    }
}
