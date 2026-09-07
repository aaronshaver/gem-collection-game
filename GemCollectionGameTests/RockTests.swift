import XCTest
@testable import GemCollectionGame

final class RockTests: XCTestCase {
    func testSeedRecreatesEveryAppearanceProperty() {
        let original = Rock(id: 7, seed: 123456)
        XCTAssertEqual(original, Rock(id: original.id, seed: original.seed))
        XCTAssertNotEqual(original.outline, Rock(id: 7, seed: 987654).outline)
    }

    func testSerializationPreservesAppearance() throws {
        let rock = Rock(id: 0, seed: .max)
        let data = try JSONEncoder().encode(rock)
        XCTAssertEqual(rock, try JSONDecoder().decode(Rock.self, from: data))
    }

    func testBoardRestoresAllFortyFiveRocksAfterRelaunch() throws {
        let suite = "RockTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = RockBoard(defaults: defaults).rocks
        let restored = RockBoard(defaults: defaults).rocks
        XCTAssertEqual(original.count, 45)
        XCTAssertEqual(Set(original.map(\.id)).count, 45)
        XCTAssertEqual(original, restored)
        XCTAssertGreaterThan(Set(original.map(\.seed)).count, 1)
    }

    func testOldBoardAddsFiveRocksAndUpgradesAppearanceWithoutLosingSeeds() throws {
        let suite = "RockMigrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let old = (0..<40).map { Rock(id: $0, seed: UInt64($0 + 100)) }
        let data = try JSONEncoder().encode(old)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        for index in json.indices { json[index]["generationVersion"] = 1 }
        defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: "rockBoard.appearances.v1")
        let updated = RockBoard(defaults: defaults).rocks
        XCTAssertEqual(updated.count, 45)
        XCTAssertEqual(Array(updated.prefix(40)).map(\.seed), old.map(\.seed))
        XCTAssertEqual(Array(updated.prefix(40)).map(\.id), old.map(\.id))
        XCTAssertTrue(updated.allSatisfy { $0.generationVersion == 2 })
        XCTAssertEqual(updated, RockBoard(defaults: defaults).rocks)
    }

    func testGeneratedGeometryStaysWithinCell() {
        for seed in 0..<100 {
            let rock = Rock(id: seed, seed: UInt64(seed))
            for point in rock.outline + rock.chips.flatMap(\.points) {
                XCTAssertTrue((0...1).contains(point.x))
                XCTAssertTrue((0...1).contains(point.y))
            }
        }
    }
}
