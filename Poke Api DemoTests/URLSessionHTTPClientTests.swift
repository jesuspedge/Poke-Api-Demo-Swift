import Foundation
import Testing

@testable import Poke_Api_Demo

// Runs the real URLSession stack against StubURLProtocol, whose handler is shared.
@Suite(.serialized)
struct URLSessionHTTPClientTests {
    private let client = URLSessionHTTPClient(session: .stubbed())

    // MARK: - HTTP client
    @Test func returnsBodyAndStatusUnchanged() async throws {
        StubURLProtocol.setHandler { _ in (418, Data("teapot".utf8)) }

        let (data, response) = try await client.data(from: URL(string: "https://example.com/brew")!)

        #expect(String(decoding: data, as: UTF8.self) == "teapot")
        #expect((response as? HTTPURLResponse)?.statusCode == 418)
    }

    @Test func requestsTheGivenURLWithGET() async throws {
        let recorder = RequestRecorder()
        StubURLProtocol.setHandler { request in
            recorder.record(request.url!)
            #expect(request.httpMethod == "GET")
            return (200, Data())
        }
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=40")!

        _ = try await client.data(from: url)

        #expect(recorder.all == [url])
    }

    @Test func transportErrorsPropagate() async {
        StubURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }

        await #expect {
            try await client.data(from: URL(string: "https://example.com")!)
        } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    // MARK: - Remote source over URLSession
    @Test func pokemonIsDecodedFromTheResponse() async throws {
        StubURLProtocol.setHandler { request in
            #expect(request.url?.absoluteString == "https://pokeapi.co/api/v2/pokemon/25")
            return (200, PokemonJSON.make(id: 25, name: "pikachu", types: ["electric"]))
        }
        let source = PokemonRemoteSource(client: client)

        let pokemon = try await source.getPokemon(id: 25).get()

        #expect(pokemon.name == "pikachu")
        #expect(pokemon.types == [.electric])
    }

    @Test func notFoundFailsWithHTTPStatus() async {
        StubURLProtocol.setHandler { _ in (404, Data("Not Found".utf8)) }
        let source = PokemonRemoteSource(client: client)

        #expect(await source.getPokemon(id: 99_999) == .failure(.httpStatus(404)))
    }

    @Test func malformedBodyFailsWithDecodingError() async {
        StubURLProtocol.setHandler { _ in (200, Data("<html>".utf8)) }
        let source = PokemonRemoteSource(client: client)

        let result = await source.getPokemon(id: 1)

        guard case .failure(.decodingError) = result else {
            Issue.record("Expected decodingError, got \(result)")
            return
        }
    }

    @Test func offlineFailsWithNetworkError() async {
        StubURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }
        let source = PokemonRemoteSource(client: client)

        let result = await source.getPokemon(id: 1)

        guard case .failure(.networkError) = result else {
            Issue.record("Expected networkError, got \(result)")
            return
        }
    }

    @Test func offlineServesTheSavedPokemon() async throws {
        StubURLProtocol.setHandler { _ in throw URLError(.notConnectedToInternet) }
        let cache = InMemoryPokemonCache()
        await cache.store([.fixture(id: 1, name: "bulbasaur")])
        let source = PokemonRemoteSource(client: client, cache: cache)

        #expect(try await source.getPokemon(id: 1).get().name == "bulbasaur")
    }
}
