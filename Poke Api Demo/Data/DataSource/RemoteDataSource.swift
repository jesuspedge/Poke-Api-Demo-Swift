//
//  ApiNetwork.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

class PokemonRemoteSource: PokemonRepository {
    private let baseUrl = "https://pokeapi.co/api/v2/pokemon/"
    private let mapper = PokemonMapper()

    func getPokemons() async -> Result<[PokemonEntity], AppError> {
        do {
            
            var pokemons: [PokemonEntity] = []
            for number in 1...20 {
                let url = URL(string: "\(baseUrl)\(number)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let model = try JSONDecoder().decode(PokemonModel.self, from: data)
                pokemons.append(mapper.toPokemonEntity(model))
            }
            
            return .success(pokemons)
            
        } catch is DecodingError {
            return .failure(.decodingError("Failed to decode Pokemon data"))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}
