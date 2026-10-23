protocol PokemonCache: Sendable {
    func pokemon(id: Int) async -> PokemonEntity?
    func store(_ pokemons: [PokemonEntity]) async
}

actor InMemoryPokemonCache: PokemonCache {
    private var storage: [Int: PokemonEntity] = [:]

    func pokemon(id: Int) -> PokemonEntity? {
        storage[id]
    }

    func store(_ pokemons: [PokemonEntity]) {
        for pokemon in pokemons {
            storage[pokemon.id] = pokemon
        }
    }
}
