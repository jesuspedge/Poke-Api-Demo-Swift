enum FavoritesState: Equatable {
    case initial
    case loading
    case success([PokemonEntity])
    case error(String)
}
