import Testing
@testable import Poke_Api_Demo

@MainActor
struct PokemonDetailViewModelTests {
    @Test func loadIfNeededPublishesPokemon() async {
        let pokemon = PokemonEntity.fixture(id: 4, name: "charmander")
        let viewModel = PokemonDetailViewModel(
            pokemonId: 4,
            repository: StubPokemonRepository(detailResult: .success(pokemon)),
            favorites: StubFavoritesRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(pokemon))
    }

    @Test func loadIfNeededPublishesLocalizedErrorMessage() async {
        let error = AppError.httpStatus(404)
        let viewModel = PokemonDetailViewModel(
            pokemonId: 1,
            repository: StubPokemonRepository(detailResult: .failure(error)),
            favorites: StubFavoritesRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func loadIfNeededOnlyFetchesOnce() async {
        let repository = StubPokemonRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository, favorites: StubFavoritesRepository())

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test func reloadRecoversAfterError() async {
        let repository = StubPokemonRepository(detailResult: .failure(.unknown))
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository, favorites: StubFavoritesRepository())
        await viewModel.loadIfNeeded()

        repository.setDetailResult(.success(.fixture()))
        await viewModel.reload()

        #expect(viewModel.state == .success(.fixture()))
    }

    // MARK: - Favorites
    @Test func loadsFavoriteStatus() async {
        let favorites = StubFavoritesRepository(favorites: [.fixture(id: 1)])
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites)

        await viewModel.loadIfNeeded()

        #expect(viewModel.isFavorite)
    }

    @Test func toggleFavoritePersistsBothWays() async {
        let favorites = StubFavoritesRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites)
        await viewModel.loadIfNeeded()

        await viewModel.toggleFavorite()
        #expect(viewModel.isFavorite)
        #expect(favorites.ids == [1])

        await viewModel.toggleFavorite()
        #expect(!viewModel.isFavorite)
        #expect(favorites.savedChanges.map(\.isFavorite) == [true, false])
    }

    @Test func failedSaveRevertsAndShowsMessage() async {
        let favorites = StubFavoritesRepository()
        let error = AppError.persistence("disk full")
        favorites.setSaveError(error)
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites)
        await viewModel.loadIfNeeded()

        await viewModel.toggleFavorite()

        #expect(!viewModel.isFavorite)
        #expect(viewModel.favoriteErrorMessage == error.localizedDescription)
    }

    @Test func toggleFavoriteIsNoOpBeforeLoad() async {
        let favorites = StubFavoritesRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites)

        await viewModel.toggleFavorite()

        #expect(!viewModel.isFavorite)
        #expect(favorites.savedChanges.isEmpty)
    }
}
