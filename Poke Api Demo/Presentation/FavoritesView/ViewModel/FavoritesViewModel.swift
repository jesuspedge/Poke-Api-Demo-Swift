import Observation

@Observable
@MainActor
final class FavoritesViewModel {
    var state: FavoritesState = .initial
    var removeErrorMessage: String?

    private let favorites: FavoritesRepository

    init(favorites: FavoritesRepository) {
        self.favorites = favorites
    }

    // Runs on every appearance, since favorites change on other screens.
    // Only the first load shows the spinner; later loads update the list in place.
    func load() async {
        if state == .initial {
            state = .loading
        }

        let result = await favorites.favorites()
        guard !Task.isCancelled else {
            if state == .loading { state = .initial }
            return
        }

        switch result {
        case .success(let pokemons):
            state = .success(pokemons)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    func remove(_ pokemon: PokemonEntity) async {
        guard case .success(let pokemons) = state else { return }

        switch await favorites.setFavorite(false, for: pokemon) {
        case .success:
            state = .success(pokemons.filter { $0.id != pokemon.id })
        case .failure(let error):
            removeErrorMessage = error.localizedDescription
        }
    }
}
