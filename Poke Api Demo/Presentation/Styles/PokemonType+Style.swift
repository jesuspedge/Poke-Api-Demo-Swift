import SwiftUI

extension PokemonType {
    var displayName: String { rawValue.capitalized }

    // The standard type colors. The light shades are darkened where needed to reach 3:1 on white,
    // and the dark shades lightened to reach 4:1 on black.
    var palette: ColorPair {
        switch self {
        case .normal: ColorPair(light: 0x92916A, dark: 0xA8A77A)
        case .fire: ColorPair(light: 0xD7752B, dark: 0xEE8130)
        case .water: ColorPair(light: 0x618DEB, dark: 0x6390F0)
        case .grass: ColorPair(light: 0x609C3C, dark: 0x7AC74C)
        case .electric: ColorPair(light: 0xA88E1E, dark: 0xF7D02C)
        case .ice: ColorPair(light: 0x689795, dark: 0x96D9D6)
        case .fighting: ColorPair(light: 0xC22E28, dark: 0xC94641)
        case .poison: ColorPair(light: 0xA33EA1, dark: 0xAA4DA8)
        case .ground: ColorPair(light: 0xA78D4B, dark: 0xE2BF65)
        case .flying: ColorPair(light: 0x9981DC, dark: 0xA98FF3)
        case .psychic: ColorPair(light: 0xF45384, dark: 0xF95587)
        case .bug: ColorPair(light: 0x889715, dark: 0xA6B91A)
        case .rock: ColorPair(light: 0xA18F30, dark: 0xB6A136)
        case .ghost: ColorPair(light: 0x735797, dark: 0x7E649F)
        case .dragon: ColorPair(light: 0x6F35FC, dark: 0x804CFC)
        case .dark: ColorPair(light: 0x705746, dark: 0x867062)
        case .steel: ColorPair(light: 0x8D8D9E, dark: 0xB7B7CE)
        case .fairy: ColorPair(light: 0xC1789C, dark: 0xD685AD)
        }
    }

    var color: Color { palette.color }

    // Text drawn on a filled badge of this type.
    var colorOnFill: Color { palette.textOnFill.color }

    var icon: String {
        switch self {
        case .normal: "circle.fill"
        case .fire: "flame.fill"
        case .water: "drop.fill"
        case .grass: "leaf.fill"
        case .electric: "bolt.fill"
        case .ice: "snowflake"
        case .fighting: "figure.boxing"
        case .poison: "allergens"
        case .ground: "mountain.2.fill"
        case .flying: "wind"
        case .psychic: "eye.fill"
        case .bug: "ladybug.fill"
        case .rock: "hexagon.fill"
        case .ghost: "moon.stars.fill"
        case .dragon: "lizard.fill"
        case .dark: "moon.fill"
        case .steel: "shield.fill"
        case .fairy: "sparkles"
        }
    }
}
