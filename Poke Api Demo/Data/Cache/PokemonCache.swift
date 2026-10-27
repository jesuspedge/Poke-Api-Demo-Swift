protocol PokemonCache: Sendable {
    func pokemon(id: Int) async -> PokemonEntity?
    func store(_ pokemons: [PokemonEntity]) async
    // Saved Pokémon sorted by id, for browsing while offline.
    func pokemons(offset: Int, limit: Int) async -> [PokemonEntity]

    func index() async -> [PokemonSummary]?
    func storeIndex(_ index: [PokemonSummary]) async

    func pokemonIDs(ofType type: PokemonType) async -> Set<Int>?
    func storePokemonIDs(_ ids: Set<Int>, ofType type: PokemonType) async
}

actor InMemoryPokemonCache: PokemonCache {
    private var storage: [Int: PokemonEntity] = [:]
    private var summaries: [PokemonSummary]?
    private var idsByType: [PokemonType: Set<Int>] = [:]

    func pokemon(id: Int) -> PokemonEntity? {
        storage[id]
    }

    func store(_ pokemons: [PokemonEntity]) {
        for pokemon in pokemons {
            storage[pokemon.id] = pokemon
        }
    }

    func pokemons(offset: Int, limit: Int) -> [PokemonEntity] {
        Array(storage.values.sorted { $0.id < $1.id }.dropFirst(offset).prefix(limit))
    }

    func index() -> [PokemonSummary]? {
        summaries
    }

    func storeIndex(_ index: [PokemonSummary]) {
        summaries = index
    }

    func pokemonIDs(ofType type: PokemonType) -> Set<Int>? {
        idsByType[type]
    }

    func storePokemonIDs(_ ids: Set<Int>, ofType type: PokemonType) {
        idsByType[type] = ids
    }
}
