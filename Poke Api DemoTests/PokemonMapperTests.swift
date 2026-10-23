import Foundation
import Testing
@testable import Poke_Api_Demo

struct PokemonMapperTests {
    private let mapper = PokemonMapper()

    @Test func convertsDecimetresAndHectogramsToMetricUnits() throws {
        let entity = mapper.toPokemonEntity(try PokemonJSON.model())

        #expect(entity.heightInMeters == 0.7)
        #expect(entity.weightInKg == 6.9)
    }

    @Test func mapsTypesToEnumAndDropsUnknownValues() throws {
        let entity = mapper.toPokemonEntity(try PokemonJSON.model(types: ["grass", "shadow", "poison"]))

        #expect(entity.types == [.grass, .poison])
        #expect(entity.primaryType == .grass)
    }

    @Test func primaryTypeFallsBackToNormalWhenNoTypesAreKnown() throws {
        let entity = mapper.toPokemonEntity(try PokemonJSON.model(types: ["shadow"]))

        #expect(entity.types.isEmpty)
        #expect(entity.primaryType == .normal)
    }

    @Test func mapsArtworkURL() throws {
        let entity = mapper.toPokemonEntity(try PokemonJSON.model())

        #expect(entity.artworkURL == URL(string: "https://example.com/1.png"))
    }

    @Test func missingArtworkBecomesNil() throws {
        let entity = mapper.toPokemonEntity(try PokemonJSON.model(artwork: nil))

        #expect(entity.artworkURL == nil)
    }

    @Test func mappingTheSameModelTwiceProducesEqualEntities() throws {
        let model = try PokemonJSON.model()

        let first = mapper.toPokemonEntity(model)
        let second = mapper.toPokemonEntity(model)

        #expect(first == second)
        #expect(first.stats.map(\.id) == ["hp", "attack"])
        #expect(first.abilities.map(\.id) == ["overgrow", "chlorophyll"])
    }
}
