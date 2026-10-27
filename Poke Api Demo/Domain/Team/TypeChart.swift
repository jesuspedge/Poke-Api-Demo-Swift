// The Gen 6+ type chart (unchanged since Fairy was added).
enum TypeChart {
    private struct Matchups {
        var superEffective: Set<PokemonType> = []
        var notVeryEffective: Set<PokemonType> = []
        var noEffect: Set<PokemonType> = []
    }

    /// The damage multiplier of an `attack` move against a single `defense` type: 0, 0.5, 1 or 2.
    static func effectiveness(of attack: PokemonType, against defense: PokemonType) -> Double {
        let matchups = matchups(for: attack)
        if matchups.noEffect.contains(defense) { return 0 }
        if matchups.superEffective.contains(defense) { return 2 }
        if matchups.notVeryEffective.contains(defense) { return 0.5 }
        return 1
    }

    /// The combined multiplier against every type of a Pokémon: 0, 0.25, 0.5, 1, 2 or 4.
    static func effectiveness(of attack: PokemonType, against types: [PokemonType]) -> Double {
        types.reduce(1) { $0 * effectiveness(of: attack, against: $1) }
    }

    private static func matchups(for attack: PokemonType) -> Matchups {
        switch attack {
        case .normal:
            Matchups(notVeryEffective: [.rock, .steel], noEffect: [.ghost])
        case .fire:
            Matchups(superEffective: [.grass, .ice, .bug, .steel],
                     notVeryEffective: [.fire, .water, .rock, .dragon])
        case .water:
            Matchups(superEffective: [.fire, .ground, .rock],
                     notVeryEffective: [.water, .grass, .dragon])
        case .electric:
            Matchups(superEffective: [.water, .flying],
                     notVeryEffective: [.electric, .grass, .dragon],
                     noEffect: [.ground])
        case .grass:
            Matchups(superEffective: [.water, .ground, .rock],
                     notVeryEffective: [.fire, .grass, .poison, .flying, .bug, .dragon, .steel])
        case .ice:
            Matchups(superEffective: [.grass, .ground, .flying, .dragon],
                     notVeryEffective: [.fire, .water, .ice, .steel])
        case .fighting:
            Matchups(superEffective: [.normal, .ice, .rock, .dark, .steel],
                     notVeryEffective: [.poison, .flying, .psychic, .bug, .fairy],
                     noEffect: [.ghost])
        case .poison:
            Matchups(superEffective: [.grass, .fairy],
                     notVeryEffective: [.poison, .ground, .rock, .ghost],
                     noEffect: [.steel])
        case .ground:
            Matchups(superEffective: [.fire, .electric, .poison, .rock, .steel],
                     notVeryEffective: [.grass, .bug],
                     noEffect: [.flying])
        case .flying:
            Matchups(superEffective: [.grass, .fighting, .bug],
                     notVeryEffective: [.electric, .rock, .steel])
        case .psychic:
            Matchups(superEffective: [.fighting, .poison],
                     notVeryEffective: [.psychic, .steel],
                     noEffect: [.dark])
        case .bug:
            Matchups(superEffective: [.grass, .psychic, .dark],
                     notVeryEffective: [.fire, .fighting, .poison, .flying, .ghost, .steel, .fairy])
        case .rock:
            Matchups(superEffective: [.fire, .ice, .flying, .bug],
                     notVeryEffective: [.fighting, .ground, .steel])
        case .ghost:
            Matchups(superEffective: [.psychic, .ghost],
                     notVeryEffective: [.dark],
                     noEffect: [.normal])
        case .dragon:
            Matchups(superEffective: [.dragon], notVeryEffective: [.steel], noEffect: [.fairy])
        case .dark:
            Matchups(superEffective: [.psychic, .ghost],
                     notVeryEffective: [.fighting, .dark, .fairy])
        case .steel:
            Matchups(superEffective: [.ice, .rock, .fairy],
                     notVeryEffective: [.fire, .water, .electric, .steel])
        case .fairy:
            Matchups(superEffective: [.fighting, .dragon, .dark],
                     notVeryEffective: [.fire, .poison, .steel])
        }
    }
}
