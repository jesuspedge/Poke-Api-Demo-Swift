struct PokemonPage: Hashable, Sendable {
    let pokemons: [PokemonEntity]
    let nextOffset: Int?
    // Served from saved Pokémon because the network was unreachable.
    var isOffline = false

    var hasMore: Bool { nextOffset != nil }
}
