protocol TeamRepository: Sendable {
    // Members in the order they were added
    func team() async -> Result<[PokemonEntity], AppError>
    func isOnTeam(id: Int) async -> Bool
    // Fails with .teamFull once the team has TeamAnalysis.maxTeamSize members; re-adding a member is a no-op.
    func addToTeam(_ pokemon: PokemonEntity) async -> Result<Void, AppError>
    func removeFromTeam(id: Int) async -> Result<Void, AppError>
}
