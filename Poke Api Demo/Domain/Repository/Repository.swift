//
//  Respository.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

protocol PokemonRepository {
    
    // getAllPokemons
    func getPokemons() async -> Result<[PokemonEntity], AppError>
    
    // getSinglePokemon
    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError>
}
