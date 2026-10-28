import Foundation
import Testing
@testable import Poke_Api_Demo

struct PokemonRemoteSourceTests {
    @Test func getPokemonDecodesAndMapsResponse() async throws {
        let client = StubHTTPClient { url in
            #expect(url.absoluteString == "https://pokeapi.co/api/v2/pokemon/1")
            return (PokemonJSON.make(), 200)
        }
        let source = PokemonRemoteSource(client: client)

        let pokemon = try await source.getPokemon(id: 1).get()

        #expect(pokemon.name == "bulbasaur")
        #expect(pokemon.types == [.grass, .poison])
    }

    @Test func nonSuccessStatusCodeFailsWithHTTPStatus() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in (Data(), 404) })

        let result = await source.getPokemon(id: 1)

        #expect(result == .failure(.httpStatus(404)))
    }

    @Test func malformedJSONFailsWithDecodingError() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in (Data("{}".utf8), 200) })

        let result = await source.getPokemon(id: 1)

        guard case .failure(.decodingError) = result else {
            Issue.record("Expected decodingError, got \(result)")
            return
        }
    }

    @Test func transportErrorFailsWithNetworkError() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in throw URLError(.notConnectedToInternet) })

        let result = await source.getPokemon(id: 1)

        guard case .failure(.networkError) = result else {
            Issue.record("Expected networkError, got \(result)")
            return
        }
    }

    @Test func getPokemonsRequestsPageWithLimitAndOffset() async throws {
        let recorder = RequestRecorder()
        let client = StubHTTPClient { url in
            recorder.record(url)
            return (PokemonJSON.page(ids: []), 200)
        }
        let source = PokemonRemoteSource(client: client)

        _ = try await source.getPokemons(offset: 40, limit: 20).get()

        #expect(recorder.all.map(\.absoluteString) == ["https://pokeapi.co/api/v2/pokemon?limit=20&offset=40"])
    }

    @Test func getPokemonsKeepsApiOrderAndComputesNextOffset() async throws {
        let ids = [3, 1, 10001, 2]
        let source = PokemonRemoteSource(client: Self.pagedClient(ids: ids, next: "https://pokeapi.co/api/v2/pokemon?offset=24&limit=4"))

        let page = try await source.getPokemons(offset: 20, limit: 4).get()

        #expect(page.pokemons.map(\.id) == ids)
        #expect(page.nextOffset == 24)
    }

    @Test func getPokemonsLastPageHasNoNextOffset() async throws {
        let source = PokemonRemoteSource(client: Self.pagedClient(ids: [1, 2], next: nil))

        let page = try await source.getPokemons(offset: 0, limit: 20).get()

        #expect(page.nextOffset == nil)
        #expect(!page.hasMore)
    }

    @Test func getPokemonsFailsWhenAnyDetailRequestFails() async {
        let client = StubHTTPClient { url in
            if url.query != nil { return (PokemonJSON.page(ids: Array(1...10)), 200) }
            return url.lastPathComponent == "7" ? (Data(), 500) : (PokemonJSON.make(), 200)
        }
        let source = PokemonRemoteSource(client: client)

        let result = await source.getPokemons(offset: 0, limit: 10)

        #expect(result == .failure(.httpStatus(500)))
    }

    @Test func getPokemonUsesCacheFilledByPage() async throws {
        let recorder = RequestRecorder()
        let source = PokemonRemoteSource(client: Self.pagedClient(ids: [1, 2], next: nil, recorder: recorder))

        _ = try await source.getPokemons(offset: 0, limit: 2).get()
        let requestsAfterPage = recorder.all.count
        let pokemon = try await source.getPokemon(id: 2).get()

        #expect(pokemon.id == 2)
        #expect(recorder.all.count == requestsAfterPage)
    }

    @Test func getPokemonsByIDsKeepsRequestedOrder() async throws {
        let source = PokemonRemoteSource(client: Self.pagedClient(ids: [], next: nil))

        let pokemons = try await source.getPokemons(ids: [25, 4, 10080]).get()

        #expect(pokemons.map(\.id) == [25, 4, 10080])
    }

    @Test func getPokemonIndexRequestsEveryNameOnceAndCachesIt() async throws {
        let recorder = RequestRecorder()
        let source = PokemonRemoteSource(client: Self.pagedClient(ids: [1, 25], next: nil, recorder: recorder))

        let index = try await source.getPokemonIndex().get()
        _ = try await source.getPokemonIndex().get()

        #expect(index == [PokemonSummary(id: 1, name: "pokemon-1"), PokemonSummary(id: 25, name: "pokemon-25")])
        #expect(recorder.all.map(\.absoluteString) == ["https://pokeapi.co/api/v2/pokemon?limit=100000&offset=0"])
    }

    @Test func getPokemonIDsOfTypeDecodesMembersAndCachesThem() async throws {
        let recorder = RequestRecorder()
        let client = StubHTTPClient { url in
            recorder.record(url)
            return (PokemonJSON.typeDetail(ids: [4, 5, 10034]), 200)
        }
        let source = PokemonRemoteSource(client: client)

        let ids = try await source.getPokemonIDs(ofType: .fire).get()
        _ = try await source.getPokemonIDs(ofType: .fire).get()

        #expect(ids == [4, 5, 10034])
        #expect(recorder.all.map(\.absoluteString) == ["https://pokeapi.co/api/v2/type/fire"])
    }

    @Test func getPokemonIDsOfTypeFailsWithHTTPStatus() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in (Data(), 404) })

        let result = await source.getPokemonIDs(ofType: .ice)

        #expect(result == .failure(.httpStatus(404)))
    }

    // MARK: - Offline fallback
    @Test func unreachableNetworkFallsBackToSavedPokemon() async throws {
        let cache = InMemoryPokemonCache()
        await cache.store([25, 1, 4].map { PokemonEntity.fixture(id: $0) })
        let client = StubHTTPClient { _ in throw URLError(.notConnectedToInternet) }
        let source = PokemonRemoteSource(client: client, cache: cache)

        let page = try await source.getPokemons(offset: 0, limit: 2).get()

        #expect(page.isOffline)
        #expect(page.pokemons.map(\.id) == [1, 4])
        #expect(page.nextOffset == 2)
    }

    @Test func offlineLastSavedPageHasNoNextOffset() async throws {
        let cache = InMemoryPokemonCache()
        await cache.store([.fixture(id: 1)])
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in throw URLError(.timedOut) }, cache: cache)

        let page = try await source.getPokemons(offset: 0, limit: 20).get()

        #expect(page.nextOffset == nil)
    }

    @Test func unreachableNetworkWithNothingSavedFails() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in throw URLError(.notConnectedToInternet) })

        let result = await source.getPokemons(offset: 0, limit: 20)

        guard case .failure(.networkError) = result else {
            Issue.record("Expected networkError, got \(result)")
            return
        }
    }

    @Test func serverErrorDoesNotFallBack() async {
        let cache = InMemoryPokemonCache()
        await cache.store([.fixture(id: 1)])
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in (Data(), 500) }, cache: cache)

        let result = await source.getPokemons(offset: 0, limit: 20)

        #expect(result == .failure(.httpStatus(500)))
    }

    // MARK: - Evolution chain
    @Test func getEvolutionChainRequestsSpeciesThenChainAndCachesIt() async throws {
        let recorder = RequestRecorder()
        let source = PokemonRemoteSource(client: Self.evolutionClient(recorder: recorder))

        let chain = try await source.getEvolutionChain(pokemonID: 2).get()
        // Another member of the same chain is served from the cache.
        let again = try await source.getEvolutionChain(pokemonID: 3).get()

        #expect(chain == .fixture())
        #expect(again == .fixture())
        #expect(recorder.all.map(\.absoluteString) == [
            "https://pokeapi.co/api/v2/pokemon-species/2",
            "https://pokeapi.co/api/v2/evolution-chain/1/",
        ])
    }

    @Test func alternateFormReadsItsSpeciesFirst() async throws {
        let recorder = RequestRecorder()
        let source = PokemonRemoteSource(client: Self.evolutionClient(recorder: recorder))

        _ = try await source.getEvolutionChain(pokemonID: 10033).get()

        #expect(recorder.all.map(\.absoluteString).first == "https://pokeapi.co/api/v2/pokemon/10033")
        #expect(recorder.all.map(\.absoluteString).dropFirst().first == "https://pokeapi.co/api/v2/pokemon-species/3")
    }

    @Test func speciesWithoutChainGivesASingleStage() async throws {
        let client = StubHTTPClient { _ in (PokemonJSON.species(id: 128, name: "tauros", chainID: nil), 200) }
        let source = PokemonRemoteSource(client: client)

        let chain = try await source.getEvolutionChain(pokemonID: 128).get()

        #expect(chain.stages.map { $0.map(\.species.name) } == [["tauros"]])
    }

    @Test func getEvolutionChainFailsWithHTTPStatus() async {
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in (Data(), 404) })

        #expect(await source.getEvolutionChain(pokemonID: 1) == .failure(.httpStatus(404)))
    }

    @Test func savedChainIsUsedOffline() async throws {
        let cache = InMemoryPokemonCache()
        await cache.storeEvolutionChain(.fixture())
        let source = PokemonRemoteSource(client: StubHTTPClient { _ in throw URLError(.notConnectedToInternet) }, cache: cache)

        #expect(try await source.getEvolutionChain(pokemonID: 1).get() == .fixture())
    }

    // MARK: - Helpers
    private static func pagedClient(ids: [Int], next: String?, recorder: RequestRecorder? = nil) -> StubHTTPClient {
        StubHTTPClient { url in
            recorder?.record(url)
            if url.query != nil {
                return (PokemonJSON.page(ids: ids, next: next), 200)
            }
            let id = try #require(Int(url.lastPathComponent))
            return (PokemonJSON.make(id: id, name: "pokemon-\(id)"), 200)
        }
    }

    // Serves the Bulbasaur line: species 1-3 point at chain 1; form 10033 is Mega Venusaur.
    private static func evolutionClient(recorder: RequestRecorder) -> StubHTTPClient {
        StubHTTPClient { url in
            recorder.record(url)
            let id = try #require(Int(url.lastPathComponent))
            switch url.deletingLastPathComponent().lastPathComponent {
            case "pokemon":
                return (PokemonJSON.speciesLink(speciesID: 3, name: "venusaur"), 200)
            case "pokemon-species":
                return (PokemonJSON.species(id: id, name: "pokemon-\(id)", chainID: 1), 200)
            default:
                return (PokemonJSON.bulbasaurChain(), 200)
            }
        }
    }
}
