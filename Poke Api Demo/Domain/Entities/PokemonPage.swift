struct PokemonPage: Hashable, Sendable {
    let pokemons: [PokemonEntity]
    let nextOffset: Int?

    var hasMore: Bool { nextOffset != nil }
}
