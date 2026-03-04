//
//  SpritesModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct SpritesModel: Codable {
    let other: OtherModel
}

struct OtherModel: Codable {
    let officialArtwork: OfficialArtworkModel

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

struct OfficialArtworkModel: Codable {
    let frontDefault: String

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}
