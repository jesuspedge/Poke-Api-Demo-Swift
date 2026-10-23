//
//  PokemonListViewModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

import Observation

@Observable
@MainActor
final class PokemonListViewModel {
    var state: PokemonListState = .initial

    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state == .initial else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        
        let result = await repository.getPokemons()

        // A cancelled .task resets the state so the next appearance loads again.
        guard !Task.isCancelled else {
            state = .initial
            return
        }

        switch result {
        case .success(let pokemons):
            state = .success(pokemons)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }
}
