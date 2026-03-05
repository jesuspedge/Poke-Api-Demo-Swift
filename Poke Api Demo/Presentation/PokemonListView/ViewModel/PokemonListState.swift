//
//  PokemonListState.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

enum PokemonListState {
    case initial
    case loading
    case success([PokemonEntity])
    case error(String)
}
