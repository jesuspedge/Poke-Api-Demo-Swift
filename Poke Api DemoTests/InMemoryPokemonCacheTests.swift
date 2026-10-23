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
}
