import Testing
@testable import Poke_Api_Demo

struct InMemoryPokemonCacheTests {
    @Test func storedPokemonCanBeRetrieved() async {
        let cache = InMemoryPokemonCache()
        let pokemon = PokemonEntity.fixture(id: 25, name: "pikachu")

        await cache.store([pokemon])

        #expect(await cache.pokemon(id: 25) == pokemon)
    }

    @Test func missReturnsNil() async {
        let cache = InMemoryPokemonCache()

        await cache.store([.fixture(id: 1)])

        #expect(await cache.pokemon(id: 2) == nil)
    }

    @Test func indexRoundTrips() async {
        let cache = InMemoryPokemonCache()
        #expect(await cache.index() == nil)

        await cache.storeIndex(.fixtures(ids: [1, 2]))

        #expect(await cache.index() == .fixtures(ids: [1, 2]))
    }

    @Test func typeIDsAreStoredPerType() async {
        let cache = InMemoryPokemonCache()

        await cache.storePokemonIDs([4, 5], ofType: .fire)

        #expect(await cache.pokemonIDs(ofType: .fire) == [4, 5])
        #expect(await cache.pokemonIDs(ofType: .water) == nil)
    }
}
