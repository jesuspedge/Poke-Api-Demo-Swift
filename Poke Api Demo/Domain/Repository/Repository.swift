//
//  Respository.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

protocol PokemonRepository: Sendable {
    
    // getPokemonPage
    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError>
    
    // getSinglePokemon
    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError>
}
