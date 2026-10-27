//
//  AppFactory.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 05/03/26.
//

import Foundation
import os
import SwiftData

// MARK: - Composition Root Factory
enum AppFactory {

    // SwiftData store shared by the cache and favorites
    private static let store = SwiftDataPokemonStore(modelContainer: makeContainer())

    // Single shared repository
    private static let repository: PokemonRepository = PokemonRemoteSource(cache: store)
    private static let favorites: FavoritesRepository = store

    @MainActor
    static func makeListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(
            repository: repository,
            search: SearchPokemonUseCase(repository: repository)
        )
    }

    @MainActor
    static func makeDetailViewModel(pokemonId: Int) -> PokemonDetailViewModel {
        PokemonDetailViewModel(pokemonId: pokemonId, repository: repository, favorites: favorites)
    }

    @MainActor
    static func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favorites: favorites)
    }

    // Falls back to an in-memory store so the app still runs if the on-disk store can't be opened.
    private static func makeContainer() -> ModelContainer {
        do {
            return try SwiftDataPokemonStore.makeContainer()
        } catch {
            Logger(subsystem: "Poke-Api-Demo", category: "Persistence")
                .error("Opening the store failed, using memory only: \(error.localizedDescription, privacy: .public)")
        }

        do {
            return try SwiftDataPokemonStore.makeContainer(inMemory: true)
        } catch {
            fatalError("Could not create an in-memory SwiftData container: \(error)")
        }
    }
}
