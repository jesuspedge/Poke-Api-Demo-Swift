//
//  PokemonModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

struct PokemonModel: Codable, Identifiable {
    let id: Int
    let name: String
    let abilities: [AbilityModel]
    let height: Int
    let sprites: SpritesModel
    let stats: [StatModel]
    let types: [TypesModel]
    let weight: Int
}
