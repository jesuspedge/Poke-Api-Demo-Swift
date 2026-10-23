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

    @Test func getPokemonsFetchesTwentyPokemonSortedById() async throws {
        let client = StubHTTPClient { url in
            let id = try #require(Int(url.lastPathComponent))
            return (PokemonJSON.make(id: id, name: "pokemon-\(id)"), 200)
        }
        let source = PokemonRemoteSource(client: client)

        let pokemons = try await source.getPokemons().get()

        #expect(pokemons.map(\.id) == Array(1...20))
    }

    @Test func getPokemonsFailsWhenAnyRequestFails() async {
        let client = StubHTTPClient { url in
            url.lastPathComponent == "7" ? (Data(), 500) : (PokemonJSON.make(), 200)
        }
        let source = PokemonRemoteSource(client: client)

        let result = await source.getPokemons()

        #expect(result == .failure(.httpStatus(500)))
    }
}
