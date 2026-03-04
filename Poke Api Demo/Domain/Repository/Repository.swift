//
//  Respository.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

protocol PokemonRepository {
    func getPokemons() async -> Result<[PokemonEntity], AppError>
}
