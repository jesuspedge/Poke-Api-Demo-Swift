//
//  PokemonMapper.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

import Foundation

struct PokemonMapper {
    func toPokemonEntity(_ model: PokemonModel) -> PokemonEntity {
        PokemonEntity(
            id: model.id,
            name: model.name,
            abilities: model.abilities.map { AbilityEntity(id: UUID(), name: $0.ability.name) },
            height: model.height,
            sprites: SpritesEntity(officialArtworkURL: model.sprites.other.officialArtwork.frontDefault),
            stats: model.stats.map { StatEntity(id: UUID(), baseStat: $0.baseStat, name: $0.stat.name) },
            types: model.types.map { TypesEntity(id: UUID(), name: $0.type.name) },
            weight: model.weight
        )
    }
}
