//
//  PokemonDetailState.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 09/03/26.
//

enum PokemonDetailState: Equatable {
    case initial
    case loading
    case success(PokemonEntity)
    case error(String)
}
