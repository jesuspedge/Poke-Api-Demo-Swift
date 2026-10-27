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
    var teamErrorMessage: String?
    private(set) var isFavorite = false
    private(set) var isOnTeam = false

    let pokemonId: Int
    private let repository: PokemonRepository
    private let favorites: FavoritesRepository
    private let team: TeamRepository

    init(pokemonId: Int, repository: PokemonRepository, favorites: FavoritesRepository, team: TeamRepository) {
        self.pokemonId = pokemonId
        self.repository = repository
        self.favorites = favorites
        self.team = team
    }

    func loadIfNeeded() async {
        guard state == .initial else { return }
        await reload()
    }

    func reload() async {
        state = .loading

        async let pokemon = repository.getPokemon(id: pokemonId)
        async let favorite = favorites.isFavorite(id: pokemonId)
        async let onTeam = team.isOnTeam(id: pokemonId)
        let (result, isFavorite, isOnTeam) = await (pokemon, favorite, onTeam)

        // A cancelled .task resets the state so the next appearance loads again.
        guard !Task.isCancelled else {
            state = .initial
            return
        }

        self.isFavorite = isFavorite
        self.isOnTeam = isOnTeam

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

    // Same as favorites: updates the button right away and reverts it if saving fails (e.g. a full team).
    func toggleTeam() async {
        guard case .success(let pokemon) = state else { return }

        let newValue = !isOnTeam
        isOnTeam = newValue

        let result = newValue ? await team.addToTeam(pokemon) : await team.removeFromTeam(id: pokemon.id)
        if case .failure(let error) = result {
            isOnTeam = !newValue
            teamErrorMessage = error.localizedDescription
        }
    }
}
