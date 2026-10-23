//
//  ApiNetwork.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

struct PokemonRemoteSource: PokemonRepository {
    private let baseUrl = "https://pokeapi.co/api/v2/pokemon/"
    private let pokemonIDs = 1...20
    private let mapper = PokemonMapper()
    private let client: HTTPClient
    private let decoder: JSONDecoder

    init(client: HTTPClient = URLSessionHTTPClient(), decoder: JSONDecoder = JSONDecoder()) {
        self.client = client
        self.decoder = decoder
    }

    func getPokemons() async -> Result<[PokemonEntity], AppError> {
        do {
            let pokemons = try await withThrowingTaskGroup(of: PokemonEntity.self) { group in
                for id in pokemonIDs {
                    group.addTask { try await fetchPokemon(id: id) }
                }

                var pokemons: [PokemonEntity] = []
                for try await pokemon in group {
                    pokemons.append(pokemon)
                }
                return pokemons.sorted { $0.id < $1.id }
            }

            return .success(pokemons)

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
        guard let url = URL(string: "\(baseUrl)\(id)") else {
            throw AppError.invalidURL
        }

        let (data, response) = try await client.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw AppError.httpStatus(httpResponse.statusCode)
        }

        let model = try decoder.decode(PokemonModel.self, from: data)
        return mapper.toPokemonEntity(model)
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
