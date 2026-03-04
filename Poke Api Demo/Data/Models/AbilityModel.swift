//
//  AbilityModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct AbilityModel: Codable {
    let ability: AbilityClassModel

    enum CodingKeys: String, CodingKey {
        case ability
    }
}

struct AbilityClassModel: Codable {
    let name: String
}
