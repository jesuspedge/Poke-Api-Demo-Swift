// /pokemon-species/{id}
struct PokemonSpeciesModel: Codable {
    let id: Int
    let name: String
    // Missing for a few species with no chain.
    let evolutionChain: ResourceURLModel?

    enum CodingKeys: String, CodingKey {
        case id, name
        case evolutionChain = "evolution_chain"
    }
}

struct ResourceURLModel: Codable {
    let url: String
}

// /evolution-chain/{id}
struct EvolutionChainModel: Codable {
    let id: Int
    let chain: ChainLinkModel
}

// Recursive: each link lists the species it evolves into.
struct ChainLinkModel: Codable {
    let species: NamedResourceModel
    let evolutionDetails: [EvolutionDetailModel]
    let evolvesTo: [ChainLinkModel]

    enum CodingKeys: String, CodingKey {
        case species
        case evolutionDetails = "evolution_details"
        case evolvesTo = "evolves_to"
    }
}

struct EvolutionDetailModel: Codable {
    let trigger: NamedResourceModel
    let minLevel: Int?
    let item: NamedResourceModel?
    let heldItem: NamedResourceModel?
    let minHappiness: Int?

    enum CodingKeys: String, CodingKey {
        case trigger, item
        case minLevel = "min_level"
        case heldItem = "held_item"
        case minHappiness = "min_happiness"
    }
}

// Only the species link of /pokemon/{id}, for alternate forms whose id isn't their species id.
struct PokemonSpeciesLinkModel: Codable {
    let species: NamedResourceModel
}
