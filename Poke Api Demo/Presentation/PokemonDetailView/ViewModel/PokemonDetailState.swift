//
//  PokemonDetailState.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 09/03/26.
//

enum PokemonDetailState {
    case initial
    case loading
    case success(PokemonEntity)
    case error(String)
}
