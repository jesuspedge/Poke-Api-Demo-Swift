//
//  PokemonModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

struct Pokemon: Codable, Identifiable {
    let id: Int
    let name: String
    let abilities: [Ability]
    let height: Int
    let sprites: Sprites
    let stats: [Stat]
    let types: [Types]
    let weight: Int
}

struct Ability: Codable, Identifiable {
    let id = UUID()
    let ability: AbilityClass
    
    enum CodingKeys: String, CodingKey {
        case ability
    }
}

struct AbilityClass: Codable {
    let name: String
}


struct Sprites: Codable {
    let other: Other
}

struct Other: Codable {
    let officialArtwork: OfficialArtwork

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable {
    let frontDefault: String

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct Stat: Codable, Identifiable {
    let id = UUID()
    let baseStat: Int
    let stat: StatClass

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

struct StatClass: Codable {
    let name: String
}

struct Types: Codable, Identifiable {
    let id = UUID()
    let type: TypeClass
    
    enum CodingKeys: String, CodingKey {
        case type
    }
}

struct TypeClass: Codable {
    let name: String
}


