import Foundation

// MARK: - Mock (Debug / Preview only)
#if DEBUG
actor MockTeamRepository: TeamRepository {
    private var seedIDs: [Int]
    private var members: [PokemonEntity] = []

    // The seed fixtures are loaded on first use, so previews can create this synchronously.
    init(seedIDs: [Int] = []) {
        self.seedIDs = seedIDs
    }

    func team() async -> Result<[PokemonEntity], AppError> {
        await loadSeedIfNeeded()
        return .success(members)
    }

    func isOnTeam(id: Int) async -> Bool {
        await loadSeedIfNeeded()
        return members.contains { $0.id == id }
    }

    func addToTeam(_ pokemon: PokemonEntity) async -> Result<Void, AppError> {
        await loadSeedIfNeeded()
        guard !members.contains(where: { $0.id == pokemon.id }) else { return .success(()) }
        guard members.count < TeamAnalysis.maxTeamSize else { return .failure(.teamFull) }
        members.append(pokemon)
        return .success(())
    }

    func removeFromTeam(id: Int) async -> Result<Void, AppError> {
        await loadSeedIfNeeded()
        members.removeAll { $0.id == id }
        return .success(())
    }

    private func loadSeedIfNeeded() async {
        guard !seedIDs.isEmpty else { return }
        let ids = seedIDs
        seedIDs = []
        if case .success(let pokemons) = await MockPokemonRepository().getPokemons(ids: ids) {
            members = pokemons
        }
    }
}
#endif
