//
//  Respository.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

protocol PokemonRepository: Sendable {
    
    // getPokemonPage
    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError>
    
    // getPokemonsByIds
    func getPokemons(ids: [Int]) async -> Result<[PokemonEntity], AppError>

    // getSinglePokemon
    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError>

    // getAllPokemonNames
    func getPokemonIndex() async -> Result<[PokemonSummary], AppError>

    // getPokemonIdsByType
    func getPokemonIDs(ofType type: PokemonType) async -> Result<Set<Int>, AppError>

    // getEvolutionChain (the chain of the Pokémon's species)
    func getEvolutionChain(pokemonID: Int) async -> Result<EvolutionChain, AppError>
}
