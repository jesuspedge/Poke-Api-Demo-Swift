import Foundation
import Testing

@testable import Poke_Api_Demo

struct SwiftDataPokemonStoreTests {
    // Each test gets its own in-memory store.
    private func makeStore() throws -> SwiftDataPokemonStore {
        SwiftDataPokemonStore(modelContainer: try SwiftDataPokemonStore.makeContainer(inMemory: true))
    }

    // MARK: - Cache
    @Test func storedPokemonRoundTripsAllFields() async throws {
        let store = try makeStore()
        let pokemon = PokemonEntity(
            id: 6,
            name: "charizard",
            abilities: [AbilityEntity(name: "blaze"), AbilityEntity(name: "solar-power")],
            heightInMeters: 1.7,
            weightInKg: 90.5,
            artworkURL: URL(string: "https://example.com/6.png"),
            stats: [StatEntity(name: "hp", baseStat: 78), StatEntity(name: "speed", baseStat: 100)],
            types: [.fire, .flying]
        )

        await store.store([pokemon])

        #expect(await store.pokemon(id: 6) == pokemon)
        #expect(await store.pokemon(id: 7) == nil)
    }

    @Test func storingAgainUpdatesWithoutDuplicating() async throws {
        let store = try makeStore()
        await store.store([.fixture(id: 1, name: "old")])

        await store.store([.fixture(id: 1, name: "bulbasaur")])

        #expect(await store.pokemon(id: 1)?.name == "bulbasaur")
        #expect(await store.pokemons(offset: 0, limit: 10).count == 1)
    }

    @Test func storingAFavoriteAgainKeepsItFavorited() async throws {
        let store = try makeStore()
        _ = await store.setFavorite(true, for: .fixture(id: 25))

        await store.store([.fixture(id: 25, name: "pikachu")])

        #expect(await store.isFavorite(id: 25))
        #expect(try await store.favorites().get().map(\.name) == ["pikachu"])
    }

    @Test func savedPokemonArePagedInIdOrder() async throws {
        let store = try makeStore()
        await store.store([25, 1, 10080, 4].map { PokemonEntity.fixture(id: $0) })

        let firstPage = await store.pokemons(offset: 0, limit: 3)
        let secondPage = await store.pokemons(offset: 3, limit: 3)

        #expect(firstPage.map(\.id) == [1, 4, 25])
        #expect(secondPage.map(\.id) == [10080])
    }

    @Test func indexIsNilUntilStoredThenReplaced() async throws {
        let store = try makeStore()
        #expect(await store.index() == nil)

        await store.storeIndex(.fixtures(ids: [2, 1]))
        #expect(await store.index() == .fixtures(ids: [1, 2]))

        await store.storeIndex(.fixtures(ids: [3]))
        #expect(await store.index() == .fixtures(ids: [3]))
    }

    @Test func typeMembersAreStoredPerTypeAndReplaced() async throws {
        let store = try makeStore()

        await store.storePokemonIDs([4, 5], ofType: .fire)
        await store.storePokemonIDs([4, 5, 6], ofType: .fire)

        #expect(await store.pokemonIDs(ofType: .fire) == [4, 5, 6])
        #expect(await store.pokemonIDs(ofType: .water) == nil)
    }

    // MARK: - Favorites
    @Test func favoritesAreNewestFirst() async throws {
        let store = try makeStore()

        _ = await store.setFavorite(true, for: .fixture(id: 1))
        _ = await store.setFavorite(true, for: .fixture(id: 4))

        #expect(try await store.favorites().get().map(\.id) == [4, 1])
    }

    @Test func unfavoritingRemovesFromFavoritesButKeepsCache() async throws {
        let store = try makeStore()
        _ = await store.setFavorite(true, for: .fixture(id: 1))

        _ = await store.setFavorite(false, for: .fixture(id: 1))

        #expect(try await store.favorites().get().isEmpty)
        #expect(!(await store.isFavorite(id: 1)))
        #expect(await store.pokemon(id: 1) != nil)
    }

    @Test func favoritingAnUncachedPokemonSavesIt() async throws {
        let store = try makeStore()

        let result = await store.setFavorite(true, for: .fixture(id: 133, name: "eevee"))

        #expect(throws: Never.self) { try result.get() }
        #expect(await store.pokemon(id: 133)?.name == "eevee")
    }

    // MARK: - Team
    @Test func teamMembersAreInTheOrderAdded() async throws {
        let store = try makeStore()

        for id in [25, 1, 4] {
            _ = await store.addToTeam(.fixture(id: id))
        }

        #expect(try await store.team().get().map(\.id) == [25, 1, 4])
        #expect(await store.isOnTeam(id: 1))
        #expect(!(await store.isOnTeam(id: 7)))
    }

    @Test func seventhMemberIsRejected() async throws {
        let store = try makeStore()
        for id in 1...6 {
            _ = await store.addToTeam(.fixture(id: id))
        }

        let result = await store.addToTeam(.fixture(id: 7))

        #expect(result.failureValue == .teamFull)
        #expect(try await store.team().get().count == 6)
        #expect(!(await store.isOnTeam(id: 7)))
    }

    @Test func readdingAMemberKeepsItsPlace() async throws {
        let store = try makeStore()
        _ = await store.addToTeam(.fixture(id: 1))
        _ = await store.addToTeam(.fixture(id: 4))

        let result = await store.addToTeam(.fixture(id: 1))

        #expect(throws: Never.self) { try result.get() }
        #expect(try await store.team().get().map(\.id) == [1, 4])
    }

    @Test func removingAMemberKeepsCacheAndFavorite() async throws {
        let store = try makeStore()
        _ = await store.setFavorite(true, for: .fixture(id: 25))
        _ = await store.addToTeam(.fixture(id: 25))

        _ = await store.removeFromTeam(id: 25)

        #expect(try await store.team().get().isEmpty)
        #expect(await store.isFavorite(id: 25))
        #expect(await store.pokemon(id: 25) != nil)
    }

    @Test func storingAMemberAgainKeepsItOnTheTeam() async throws {
        let store = try makeStore()
        _ = await store.addToTeam(.fixture(id: 25))

        await store.store([.fixture(id: 25, name: "pikachu")])

        #expect(try await store.team().get().map(\.name) == ["pikachu"])
    }

    // MARK: - Evolution chains
    @Test func evolutionChainIsFoundFromEveryMember() async throws {
        let store = try makeStore()

        await store.storeEvolutionChain(.fixture())

        for id in [1, 2, 3] {
            #expect(await store.evolutionChain(speciesID: id) == .fixture())
        }
        #expect(await store.evolutionChain(speciesID: 4) == nil)
    }

    @Test func storingAChainAgainReplacesIt() async throws {
        let store = try makeStore()
        await store.storeEvolutionChain(EvolutionChain(id: 1, root: .fixture(id: 1, name: "old")))

        await store.storeEvolutionChain(.fixture())

        #expect(await store.evolutionChain(speciesID: 1) == .fixture())
        #expect(await store.evolutionChain(speciesID: 3) == .fixture())
    }
}
