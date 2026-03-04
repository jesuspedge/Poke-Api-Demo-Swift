//
//  PokemonEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

import Foundation

class PokemonEntity: Identifiable {
    let id: Int
    let name: String
    let abilities: [AbilityEntity]
    let height: Int
    let sprites: SpritesEntity
    let stats: [StatEntity]
    let types: [TypesEntity]
    let weight: Int

    init(id: Int,
         name: String,
         abilities: [AbilityEntity],
         height: Int,
         sprites: SpritesEntity,
         stats: [StatEntity],
         types: [TypesEntity],
         weight: Int) {
        self.id = id
        self.name = name
        self.abilities = abilities
        self.height = height
        self.sprites = sprites
        self.stats = stats
        self.types = types
        self.weight = weight
    }
}
