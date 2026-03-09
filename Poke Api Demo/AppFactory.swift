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
}

// MARK: - Mock (Debug / Preview only)
#if DEBUG
struct MockPokemonRepository: PokemonRepository {
    func getPokemons() async -> Result<[PokemonEntity], AppError> {
        .success([
            PokemonEntity(
                id: 1,
                name: "bulbasaur",
                abilities: [
                    AbilityEntity(id: UUID(), name: "overgrow"),
                    AbilityEntity(id: UUID(), name: "chlorophyll"),
                ],
                height: 7,
                sprites: SpritesEntity(officialArtworkURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"),
                stats: [
                    StatEntity(id: UUID(), baseStat: 45, name: "hp"),
                    StatEntity(id: UUID(), baseStat: 49, name: "attack"),
                    StatEntity(id: UUID(), baseStat: 49, name: "defense"),
                    StatEntity(id: UUID(), baseStat: 65, name: "special-attack"),
                    StatEntity(id: UUID(), baseStat: 65, name: "special-defense"),
                    StatEntity(id: UUID(), baseStat: 45, name: "speed"),
                ],
                types: [
                    TypesEntity(id: UUID(), name: "grass"),
                    TypesEntity(id: UUID(), name: "poison")
                ],
                weight: 69)
        ])
    }
}
#endif
