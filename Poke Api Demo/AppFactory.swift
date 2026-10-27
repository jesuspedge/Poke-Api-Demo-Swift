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
        PokemonListViewModel(
            repository: repository,
            search: SearchPokemonUseCase(repository: repository)
        )
    }
    
    @MainActor
    static func makeDetailViewModel(pokemonId: Int) -> PokemonDetailViewModel {
        PokemonDetailViewModel(pokemonId: pokemonId, repository: repository)
    }
}
