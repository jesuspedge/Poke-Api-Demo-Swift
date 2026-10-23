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
            abilities: model.abilities.map { AbilityEntity(name: $0.ability.name) },
            heightInMeters: Double(model.height) / 10,
            weightInKg: Double(model.weight) / 10,
            artworkURL: model.sprites.other.officialArtwork.frontDefault.flatMap(URL.init(string:)),
            stats: model.stats.map { StatEntity(name: $0.stat.name, baseStat: $0.baseStat) },
            types: model.types.compactMap { PokemonType(rawValue: $0.type.name) }
        )
    }
}
