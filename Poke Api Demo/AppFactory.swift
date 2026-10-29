//
//  AppFactory.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 05/03/26.
//

import Foundation
import SwiftData
import os

// MARK: - Composition Root Factory
enum AppFactory {

    // SwiftData store shared by the cache, favorites and the team
    private static let store = SwiftDataPokemonStore(modelContainer: makeContainer())

    // Single shared repository
    private static let repository: PokemonRepository = makeRepository()
    private static let favorites: FavoritesRepository = store
    private static let team: TeamRepository = store

    @MainActor
    static func makeListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(
            repository: repository,
            search: SearchPokemonUseCase(repository: repository)
        )
    }

    @MainActor
    static func makeDetailViewModel(pokemonId: Int) -> PokemonDetailViewModel {
        PokemonDetailViewModel(pokemonId: pokemonId, repository: repository, favorites: favorites, team: team)
    }

    @MainActor
    static func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favorites: favorites)
    }

    @MainActor
    static func makeTeamViewModel() -> TeamViewModel {
        TeamViewModel(team: team)
    }

    @MainActor
    static func makeTeamPickerViewModel(excluding memberIDs: Set<Int>) -> TeamPickerViewModel {
        TeamPickerViewModel(
            search: SearchPokemonUseCase(repository: repository),
            repository: repository,
            team: team,
            excludedIDs: memberIDs
        )
    }

    private static func makeRepository() -> PokemonRepository {
        #if DEBUG
        if LaunchMode.current == .uiTesting { return MockPokemonRepository() }
        #endif
        return PokemonRemoteSource(cache: store)
    }

    // Falls back to an in-memory store so the app still runs if the on-disk store can't be opened.
    private static func makeContainer() -> ModelContainer {
        #if DEBUG
        if LaunchMode.current != .standard, let container = try? SwiftDataPokemonStore.makeContainer(inMemory: true) {
            return container
        }
        #endif

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

#if DEBUG
// Set by the UI tests through launch arguments. Both test modes start from an empty in-memory store,
// so the saved favorites and team are never touched.
enum LaunchMode {
    case standard
    // The bundled fixtures, with no network.
    case uiTesting
    // Live data, for recording the README demo.
    case demoTour

    static let current: LaunchMode = {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") { return .uiTesting }
        if arguments.contains("-demo-tour") { return .demoTour }
        return .standard
    }()
}
#endif
