import XCTest
@testable import GemCollectionGame

final class PopulationTests: XCTestCase {
    func testWeightedTableBoundariesAndValidation() throws {
        let table = try WeightedTable([("cracked", 4.0), ("disabled", 0), ("dull", 2), ("shiny", 1)])
        XCTAssertEqual(table.select(unit: 0), "cracked")
        XCTAssertEqual(table.select(unit: 0.57), "cracked")
        XCTAssertEqual(table.select(unit: 0.58), "dull")
        XCTAssertEqual(table.select(unit: 0.86), "shiny")
        XCTAssertEqual(table.select(unit: 1), "shiny")
        XCTAssertThrowsError(try WeightedTable<Int>([]))
        XCTAssertThrowsError(try WeightedTable([(1, -1.0)]))
        XCTAssertThrowsError(try WeightedTable([(1, Double.nan)]))
        XCTAssertThrowsError(try WeightedTable([(1, 0.0)]))
    }

    func testGenerationAndSerializationAreDeterministic() throws {
        let generator = try PopulationGenerator(configuration: .standard)
        let pieces = generator.generate(seed: 2026, count: 45)
        XCTAssertEqual(pieces, generator.generate(seed: 2026, count: 45))
        XCTAssertNotEqual(pieces, generator.generate(seed: 2027, count: 45))
        XCTAssertEqual(pieces, try JSONDecoder().decode([BoardPiece].self, from: JSONEncoder().encode(pieces)))
        XCTAssertEqual(Set(pieces.map(\.id)).count, 45)
        for case .gem(let gem) in pieces {
            XCTAssertEqual(gem, Gem(id: gem.id, seed: gem.seed, grade: gem.grade, color: gem.color, shape: gem.shape))
        }
    }

    func testPopulationFollowsIndependentRelativeWeights() throws {
        let config = PopulationConfiguration.standard
        let pieces = try PopulationGenerator(configuration: config).generate(seed: 987654, count: 10_000)
        let gems = pieces.compactMap { piece -> Gem? in if case .gem(let gem) = piece { return gem }; return nil }
        XCTAssertEqual(Double(gems.count) / Double(pieces.count), 0.50, accuracy: 0.02)
        for grade in config.grades {
            let fraction = Double(gems.filter { $0.grade.id == grade.id }.count) / Double(gems.count)
            XCTAssertEqual(fraction, grade.weight / 7, accuracy: 0.03)
        }
        for color in config.colors {
            let fraction = Double(gems.filter { $0.color.id == color.id }.count) / Double(gems.count)
            XCTAssertEqual(fraction, color.weight / config.colors.reduce(0) { $0 + $1.weight }, accuracy: 0.03)
        }
        for shape in config.shapes {
            let fraction = Double(gems.filter { $0.shape.id == shape.id }.count) / Double(gems.count)
            XCTAssertEqual(fraction, shape.weight / config.shapes.reduce(0) { $0 + $1.weight }, accuracy: 0.03)
        }
    }

    func testCatalogCanAddOrRemoveVariantsWithoutGeneratorChanges() throws {
        let config = PopulationConfiguration(gemProbability: 1,
            grades: [GemGrade(id: "new", name: "New", crackCount: 1, sparkleCount: 2, weight: 1)],
            colors: [GemColor(id: "cyan", name: "Cyan", red: 0, green: 0.8, blue: 0.8, weight: 1)],
            shapes: [GemShape(id: "octagon", sides: 8, weight: 1)])
        let pieces = try PopulationGenerator(configuration: config).generate(seed: 1, count: 45)
        for piece in pieces {
            guard case .gem(let gem) = piece else { return XCTFail("Expected only gems") }
            XCTAssertEqual(gem.shape.sides, 8)
            XCTAssertEqual(gem.color.id, "cyan")
            XCTAssertFalse(gem.crackPaths.isEmpty)
            XCTAssertEqual(gem.sparkles.count, 2)
        }
        var invalid = config
        invalid.shapes = [GemShape(id: "invalid", sides: 2, weight: 1)]
        XCTAssertThrowsError(try PopulationGenerator(configuration: invalid))
    }

    func testRegenerationReplacesAndPersistsTheField() throws {
        let suite = "RegenerationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let board = GameBoard(defaults: defaults)
        let previous = board.pieces
        board.regenerate()
        XCTAssertEqual(board.pieces.count, BoardLayout.cellCount)
        XCTAssertNotEqual(previous, board.pieces)
        XCTAssertEqual(board.pieces, GameBoard(defaults: defaults).pieces)
    }

    func testLegacyMigrationAndReloadKeepTheSamePopulation() throws {
        let suite = "PopulationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        _ = RockBoard(defaults: defaults).rocks
        let first = GameBoard(defaults: defaults).pieces
        XCTAssertEqual(first.count, 45)
        XCTAssertEqual(first, GameBoard(defaults: defaults).pieces)
        XCTAssertFalse(MatchRules.hasMatch(in: first))
    }
}
