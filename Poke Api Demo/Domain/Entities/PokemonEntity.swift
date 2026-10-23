//
//  PokemonEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

import Foundation

struct PokemonEntity: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let abilities: [AbilityEntity]
    let heightInMeters: Double
    let weightInKg: Double
    let artworkURL: URL?
    let stats: [StatEntity]
    let types: [PokemonType]

    var primaryType: PokemonType { types.first ?? .normal }
}
