import Testing

@testable import Poke_Api_Demo

struct TypeChartTests {
    @Test(arguments: [
        (PokemonType.fire, PokemonType.grass, 2.0),
        (.water, .fire, 2),
        (.grass, .fire, 0.5),
        (.normal, .normal, 1),
        (.fairy, .dragon, 2),
        (.steel, .fairy, 2),
        (.electric, .ground, 0),
        (.normal, .ghost, 0),
        (.ghost, .normal, 0),
        (.fighting, .ghost, 0),
        (.ground, .flying, 0),
        (.psychic, .dark, 0),
        (.poison, .steel, 0),
        (.dragon, .fairy, 0),
    ])
    func singleTypeMatchups(attack: PokemonType, defense: PokemonType, expected: Double) {
        #expect(TypeChart.effectiveness(of: attack, against: defense) == expected)
    }

    @Test(arguments: [
        (PokemonType.ice, [PokemonType.dragon, .flying], 4.0),
        (.electric, [.water, .flying], 4),
        (.fire, [.water, .rock], 0.25),
        (.ground, [.fire, .flying], 0),
        (.water, [.grass, .ground], 1),
    ])
    func dualTypeMultipliersCombine(attack: PokemonType, defense: [PokemonType], expected: Double) {
        #expect(TypeChart.effectiveness(of: attack, against: defense) == expected)
    }

    @Test func everySingleTypeValueIsAValidMultiplier() {
        for attack in PokemonType.allCases {
            for defense in PokemonType.allCases {
                #expect([0, 0.5, 1, 2].contains(TypeChart.effectiveness(of: attack, against: defense)))
            }
        }
    }

    @Test func steelResistsTenTypesAndIsImmuneToPoison() {
        let multipliers = PokemonType.allCases.map { TypeChart.effectiveness(of: $0, against: .steel) }

        #expect(multipliers.count(where: { $0 == 0.5 }) == 10)
        #expect(TypeChart.effectiveness(of: .poison, against: .steel) == 0)
    }
}
