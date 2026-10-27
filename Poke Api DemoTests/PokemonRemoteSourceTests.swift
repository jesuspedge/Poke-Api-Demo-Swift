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
}
