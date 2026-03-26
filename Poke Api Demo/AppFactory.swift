//
//  AppFactory.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 05/03/26.
//

import Foundation

// MARK: - Composition Root Factory
enum AppFactory {

    // Single shared repository
    private static let repository: PokemonRepository = PokemonRemoteSource()

    @MainActor
    static func makeListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(repository: repository)
    }
    
    @MainActor
    static func makeDetailViewModel() -> PokemonDetailViewModel {
        PokemonDetailViewModel(repository: repository)
    }
}

// MARK: - Mock (Debug / Preview only)
#if DEBUG
private extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        guard let url = self.url(forResource: filename, withExtension: "json") else {
            throw AppError.decodingError("Fixture file '\(filename).json' not found in bundle")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct MockPokemonRepository: PokemonRepository {
    private let mapper = PokemonMapper()
    private let fixtureIDs = [1, 2, 3, 4, 5]

    func getPokemons() async -> Result<[PokemonEntity], AppError> {
        do {
            let entities = try fixtureIDs.map {
                let model = try Bundle.main.decode(PokemonModel.self, from: "pokemon_\($0)")
                return mapper.toPokemonEntity(model)
            }
            return .success(entities)
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        do {
            let model = try Bundle.main.decode(PokemonModel.self, from: "pokemon_\(id)")
            return .success(mapper.toPokemonEntity(model))
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
}
#endif
