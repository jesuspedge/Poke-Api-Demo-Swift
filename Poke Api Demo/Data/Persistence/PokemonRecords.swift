import Foundation
import SwiftData

struct StoredStat: Codable {
    let name: String
    let baseStat: Int
}

@Model
final class PokemonRecord {
    @Attribute(.unique) var id: Int
    var name: String
    var heightInMeters: Double
    var weightInKg: Double
    var artworkURL: URL?
    var typeNames: [String]
    var abilityNames: [String]
    var stats: [StoredStat]
    var isFavorite = false
    var favoritedAt: Date?
    // nil when the Pokémon isn't on the team
    var teamAddedAt: Date?

    init(_ entity: PokemonEntity) {
        id = entity.id
        name = entity.name
        heightInMeters = entity.heightInMeters
        weightInKg = entity.weightInKg
        artworkURL = entity.artworkURL
        typeNames = entity.types.map(\.rawValue)
        abilityNames = entity.abilities.map(\.name)
        stats = entity.stats.map { StoredStat(name: $0.name, baseStat: $0.baseStat) }
    }

    // Refreshes the API data only; favorite and team fields belong to the user.
    func update(from entity: PokemonEntity) {
        name = entity.name
        heightInMeters = entity.heightInMeters
        weightInKg = entity.weightInKg
        artworkURL = entity.artworkURL
        typeNames = entity.types.map(\.rawValue)
        abilityNames = entity.abilities.map(\.name)
        stats = entity.stats.map { StoredStat(name: $0.name, baseStat: $0.baseStat) }
    }

    var entity: PokemonEntity {
        PokemonEntity(
            id: id,
            name: name,
            abilities: abilityNames.map { AbilityEntity(name: $0) },
            heightInMeters: heightInMeters,
            weightInKg: weightInKg,
            artworkURL: artworkURL,
            stats: stats.map { StatEntity(name: $0.name, baseStat: $0.baseStat) },
            types: typeNames.compactMap(PokemonType.init(rawValue:))
        )
    }
}

@Model
final class PokemonSummaryRecord {
    @Attribute(.unique) var id: Int
    var name: String

    init(_ summary: PokemonSummary) {
        id = summary.id
        name = summary.name
    }

    var summary: PokemonSummary {
        PokemonSummary(id: id, name: name)
    }
}

@Model
final class TypeMembersRecord {
    @Attribute(.unique) var typeName: String
    var ids: [Int]

    init(typeName: String, ids: [Int]) {
        self.typeName = typeName
        self.ids = ids
    }
}

// The whole chain as JSON: it's always read and written as one tree.
@Model
final class EvolutionChainRecord {
    @Attribute(.unique) var id: Int
    var payload: Data

    init(id: Int, payload: Data) {
        self.id = id
        self.payload = payload
    }
}

// One per species in a chain, so the chain can be found from any member.
@Model
final class EvolutionLinkRecord {
    @Attribute(.unique) var speciesID: Int
    var chainID: Int

    init(speciesID: Int, chainID: Int) {
        self.speciesID = speciesID
        self.chainID = chainID
    }
}
