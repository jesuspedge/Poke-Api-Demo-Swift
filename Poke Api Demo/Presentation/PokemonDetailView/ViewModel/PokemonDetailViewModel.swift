//
//  PokemonDetailViewModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 09/03/26.
//

import Observation

@Observable
@MainActor
final class PokemonDetailViewModel {
    var state: PokemonDetailState = .initial
    var favoriteErrorMessage: String?
    private(set) var isFavorite = false

    let pokemonId: Int
    private let repository: PokemonRepository
    private let favorites: FavoritesRepository

    init(pokemonId: Int, repository: PokemonRepository, favorites: FavoritesRepository) {
        self.pokemonId = pokemonId
        self.repository = repository
        self.favorites = favorites
    }

    func loadIfNeeded() async {
        guard state == .initial else { return }
        await reload()
    }

    func reload() async {
        state = .loading

        async let pokemon = repository.getPokemon(id: pokemonId)
        async let favorite = favorites.isFavorite(id: pokemonId)
        let (result, isFavorite) = await (pokemon, favorite)

        // A cancelled .task resets the state so the next appearance loads again.
        guard !Task.isCancelled else {
            state = .initial
            return
        }

        self.isFavorite = isFavorite

        switch result {
        case .success(let pokemon):
            state = .success(pokemon)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    // Updates the heart right away and reverts it if saving fails.
    func toggleFavorite() async {
        guard case .success(let pokemon) = state else { return }

        let newValue = !isFavorite
        isFavorite = newValue

        if case .failure(let error) = await favorites.setFavorite(newValue, for: pokemon) {
            isFavorite = !newValue
            favoriteErrorMessage = error.localizedDescription
        }
    }
}
