import SwiftUI

enum AttributePalette {
    // Shared dark pastel shades; each attribute starts again at the first color.
    private static let hexColors: [UInt32] = [
        0x435C7B, // Dusty blue
        0x784956, // Rose
        0x496B59, // Sage
        0x62517D, // Lavender
        0x76633E, // Ochre
        0x3E6A70, // Teal
        0x754B72, // Mauve
        0x566478, // Slate
        0x7C5543, // Terracotta
        0x60683F, // Olive
        0x4F527B, // Periwinkle
        0x7B4F62, // Berry
        0x3F6B64, // Sea green
        0x71604F, // Taupe
        0x67586B, // Heather
        0x466878  // Steel blue
    ]

    private static let shades: [Color] = hexColors.map { hex in
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }

    private static let colors: [Attribute: [String: Color]] = Dictionary(
        uniqueKeysWithValues: Attribute.allCases.map { attribute in
            let names = attribute.names.sorted()
            precondition(names.count <= shades.count)
            return (attribute, Dictionary(uniqueKeysWithValues: names.enumerated().map {
                ($0.element, shades[$0.offset])
            }))
        }
    )

    static func color(for attribute: Attribute, in adventurer: Adventurer) -> Color {
        colors[attribute]![attribute.value(in: adventurer)]!
    }
}
