import Foundation

// MARK: - Mock (Debug / Preview only)
#if DEBUG
actor MockFavoritesRepository: FavoritesRepository {
    private var seedIDs: [Int]
    private var stored: [PokemonEntity] = []

    // The seed fixtures are loaded on first use, so previews can create this synchronously.
    init(seedIDs: [Int] = []) {
        self.seedIDs = seedIDs
    }

    func favorites() async -> Result<[PokemonEntity], AppError> {
        await loadSeedIfNeeded()
        return .success(stored)
    }

    func isFavorite(id: Int) async -> Bool {
        await loadSeedIfNeeded()
        return stored.contains { $0.id == id }
    }

    func setFavorite(_ isFavorite: Bool, for pokemon: PokemonEntity) async -> Result<Void, AppError> {
        await loadSeedIfNeeded()
        stored.removeAll { $0.id == pokemon.id }
        if isFavorite {
            stored.insert(pokemon, at: 0)
        }
        return .success(())
    }

    private func loadSeedIfNeeded() async {
        guard !seedIDs.isEmpty else { return }
        let ids = seedIDs
        seedIDs = []
        if case .success(let pokemons) = await MockPokemonRepository().getPokemons(ids: ids) {
            stored = pokemons
        }
    }
}
#endif
