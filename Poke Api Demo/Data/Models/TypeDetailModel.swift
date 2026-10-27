struct TypeDetailModel: Codable {
    let pokemon: [TypePokemonModel]
}

struct TypePokemonModel: Codable {
    let pokemon: NamedResourceModel
}
