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

    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func fetchPokemon(id: Int) async {
        state = .loading
        
        let result = await repository.getPokemon(id: id)
        
        switch result {
        case .success(let pokemon):
            state = .success(pokemon)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }
}
