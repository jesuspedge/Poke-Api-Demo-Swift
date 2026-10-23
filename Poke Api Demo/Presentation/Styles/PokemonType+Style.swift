import SwiftUI

extension PokemonType {
    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .normal: .gray
        case .fire: .orange
        case .water: .blue
        case .grass: .green
        case .electric: .yellow
        case .ice: .cyan
        case .fighting: .red
        case .poison: .purple
        case .ground: .brown
        case .flying: .indigo
        case .psychic: .pink
        case .bug: .mint
        case .rock: .brown
        case .ghost: .indigo
        case .dragon: .teal
        case .dark: .black
        case .steel: .gray
        case .fairy: .pink
        }
    }

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
