import Foundation

struct GemColor: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let red: Double
    let green: Double
    let blue: Double
    let weight: Double
}

struct GemGrade: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let crackCount: Int
    let sparkleCount: Int
    let weight: Double
}

struct GemShape: Codable, Equatable, Identifiable {
    let id: String
    let sides: Int
    let weight: Double
}

/// Edit these data lists to add/remove variants; sampling and drawing are generic.
struct PopulationConfiguration: Codable, Equatable {
    var gemProbability: Double
    var grades: [GemGrade]
    var colors: [GemColor]
    var shapes: [GemShape]

    static let standard = PopulationConfiguration(
        gemProbability: 0.50,
        grades: [
            GemGrade(id: "cracked", name: "Cracked", crackCount: 3, sparkleCount: 0, weight: 4),
            GemGrade(id: "dull", name: "Dull", crackCount: 0, sparkleCount: 0, weight: 2),
            GemGrade(id: "shiny", name: "Shiny", crackCount: 0, sparkleCount: 3, weight: 1)
        ],
        colors: [
            GemColor(id: "red", name: "Red", red: 0.83, green: 0.08, blue: 0.15, weight: 1),
            GemColor(id: "orange", name: "Orange", red: 0.96, green: 0.34, blue: 0.045, weight: 1.0 / 2),
            GemColor(id: "yellow", name: "Yellow", red: 0.93, green: 0.73, blue: 0.06, weight: 1.0 / 3),
            GemColor(id: "green", name: "Green", red: 0.045, green: 0.65, blue: 0.29, weight: 1.0 / 5),
            GemColor(id: "blue", name: "Blue", red: 0.055, green: 0.34, blue: 0.91, weight: 1.0 / 8),
            GemColor(id: "purple", name: "Purple", red: 0.52, green: 0.15, blue: 0.83, weight: 1.0 / 13)
        ],
        shapes: [
            GemShape(id: "triangle", sides: 3, weight: 1),
            GemShape(id: "quadrilateral", sides: 4, weight: 1.0 / 2),
            GemShape(id: "pentagon", sides: 5, weight: 1.0 / 3),
            GemShape(id: "hexagon", sides: 6, weight: 1.0 / 5)
        ])
}
