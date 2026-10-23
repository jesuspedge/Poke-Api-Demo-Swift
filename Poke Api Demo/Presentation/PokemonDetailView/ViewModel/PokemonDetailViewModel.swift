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

    let pokemonId: Int
    private let repository: PokemonRepository

    init(pokemonId: Int, repository: PokemonRepository) {
        self.pokemonId = pokemonId
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state == .initial else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        
        let result = await repository.getPokemon(id: pokemonId)

        // A cancelled .task resets the state so the next appearance loads again.
        guard !Task.isCancelled else {
            state = .initial
            return
        }

        switch result {
        case .success(let pokemon):
            state = .success(pokemon)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }
}
