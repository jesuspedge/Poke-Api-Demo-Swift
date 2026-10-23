//
//  ApiNetwork.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

struct PokemonRemoteSource: PokemonRepository {
    private let baseUrl = "https://pokeapi.co/api/v2/pokemon"
    private let mapper = PokemonMapper()
    private let client: HTTPClient
    private let decoder: JSONDecoder
    private let cache: PokemonCache

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        cache: PokemonCache = InMemoryPokemonCache()
    ) {
        self.client = client
        self.decoder = decoder
        self.cache = cache
    }

    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError> {
        do {
            let page: PokemonPageModel = try await get(try listURL(offset: offset, limit: limit))
            let ids = page.results.compactMap(\.id)

            let pokemons = try await withThrowingTaskGroup(of: (Int, PokemonEntity).self) { group in
                for (index, id) in ids.enumerated() {
                    group.addTask { (index, try await fetchPokemon(id: id)) }
                }

                // Keep the API order: ids jump to 10001+ near the end of the dex.
                var indexed: [(Int, PokemonEntity)] = []
                for try await result in group {
                    indexed.append(result)
                }
                return indexed.sorted { $0.0 < $1.0 }.map(\.1)
            }

            let nextOffset = page.next == nil ? nil : offset + page.results.count
            return .success(PokemonPage(pokemons: pokemons, nextOffset: nextOffset))

        } catch {
            return .failure(mapError(error))
        }
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        do {
            return .success(try await fetchPokemon(id: id))
        } catch {
            return .failure(mapError(error))
        }
    }

    // MARK: - Helpers
    private func fetchPokemon(id: Int) async throws -> PokemonEntity {
        if let cached = await cache.pokemon(id: id) {
            return cached
        }

        guard let url = URL(string: "\(baseUrl)/\(id)") else {
            throw AppError.invalidURL
        }

        let model: PokemonModel = try await get(url)
        let pokemon = mapper.toPokemonEntity(model)
        await cache.store([pokemon])
        return pokemon
    }

    private func listURL(offset: Int, limit: Int) throws -> URL {
        var components = URLComponents(string: baseUrl)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components?.url else {
            throw AppError.invalidURL
        }
        return url
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await client.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw AppError.httpStatus(httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func mapError(_ error: Error) -> AppError {
        switch error {
        case let appError as AppError:
            appError
        case is DecodingError:
            .decodingError("Failed to decode Pokemon data")
        default:
            .networkError(error.localizedDescription)
        }
    }
}
