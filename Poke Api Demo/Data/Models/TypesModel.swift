//
//  TypesModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct TypesModel: Codable {
    let type: TypeClassModel

    enum CodingKeys: String, CodingKey {
        case type
    }
}

struct TypeClassModel: Codable {
    let name: String
}
