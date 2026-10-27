// How a team holds up against each attacking type, and which types its own types hit hard.
struct TeamAnalysis: Equatable, Sendable {
    static let maxTeamSize = 6

    struct DefensiveMatchup: Equatable, Sendable {
        let type: PokemonType
        let weak: Int
        let resistant: Int
        let immune: Int

        // More members are hurt by this type than can safely switch in on it.
        var isSharedWeakness: Bool { weak >= 2 && weak > resistant + immune }
    }

    /// One entry per attacking type, in `PokemonType.allCases` order.
    let defense: [DefensiveMatchup]
    /// Single types that at least one of the team's own types hits for 2×.
    let covered: [PokemonType]
    let uncovered: [PokemonType]

    var sharedWeaknesses: [PokemonType] {
        defense.filter(\.isSharedWeakness).map(\.type)
    }

    init(team: [PokemonEntity]) {
        defense = PokemonType.allCases.map { attack in
            let multipliers = team.map { TypeChart.effectiveness(of: attack, against: $0.types) }
            return DefensiveMatchup(
                type: attack,
                weak: multipliers.count(where: { $0 > 1 }),
                resistant: multipliers.count(where: { $0 > 0 && $0 < 1 }),
                immune: multipliers.count(where: { $0 == 0 })
            )
        }

        let attackingTypes = Set(team.flatMap(\.types))
        let isCovered = { (defense: PokemonType) in
            attackingTypes.contains { TypeChart.effectiveness(of: $0, against: defense) > 1 }
        }
        covered = PokemonType.allCases.filter(isCovered)
        uncovered = PokemonType.allCases.filter { !isCovered($0) }
    }
}
