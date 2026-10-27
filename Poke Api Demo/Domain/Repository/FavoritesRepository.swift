protocol FavoritesRepository: Sendable {

    // Most recently added first
    func favorites() async -> Result<[PokemonEntity], AppError>

    func isFavorite(id: Int) async -> Bool

    func setFavorite(_ isFavorite: Bool, for pokemon: PokemonEntity) async -> Result<Void, AppError>
}
