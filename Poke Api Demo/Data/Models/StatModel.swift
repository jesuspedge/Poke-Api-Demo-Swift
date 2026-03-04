//
//  StatModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct StatModel: Codable {
    let baseStat: Int
    let stat: StatClassModel

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

struct StatClassModel: Codable {
    let name: String
}
