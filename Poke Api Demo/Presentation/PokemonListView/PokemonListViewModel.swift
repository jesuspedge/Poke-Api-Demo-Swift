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

    init(repository: PokemonRepository = PokemonRemoteSource()) {
        self.repository = repository
    }

    func fetchPokemons() async {
        state = .loading
        let result = await repository.getPokemons()
        switch result {
        case .success(let pokemons):
            state = .success(pokemons)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }
}
