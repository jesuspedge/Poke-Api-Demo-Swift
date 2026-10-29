import Testing

@testable import Poke_Api_Demo

@MainActor
struct FavoritesViewModelTests {
    @Test func loadPublishesFavorites() async {
        let pokemons = [PokemonEntity.fixture(id: 4), .fixture(id: 1)]
        let viewModel = FavoritesViewModel(favorites: StubFavoritesRepository(favorites: pokemons))

        await viewModel.load()

        #expect(viewModel.state == .success(pokemons))
    }

    @Test func loadWithNoFavoritesPublishesEmptyList() async {
        let viewModel = FavoritesViewModel(favorites: StubFavoritesRepository())

        await viewModel.load()

        #expect(viewModel.state == .success([]))
    }

    @Test func loadPublishesLocalizedErrorMessage() async {
        let favorites = StubFavoritesRepository()
        let error = AppError.persistence("corrupt store")
        favorites.setReadError(error)
        let viewModel = FavoritesViewModel(favorites: favorites)

        await viewModel.load()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func reloadPicksUpChangesMadeElsewhere() async {
        let favorites = StubFavoritesRepository(favorites: [.fixture(id: 1)])
        let viewModel = FavoritesViewModel(favorites: favorites)
        await viewModel.load()

        _ = await favorites.setFavorite(true, for: .fixture(id: 7))
        await viewModel.load()

        #expect(viewModel.state == .success([.fixture(id: 7), .fixture(id: 1)]))
    }

    @Test func removeUnfavoritesAndDropsRow() async {
        let favorites = StubFavoritesRepository(favorites: [.fixture(id: 4), .fixture(id: 1)])
        let viewModel = FavoritesViewModel(favorites: favorites)
        await viewModel.load()

        await viewModel.remove(.fixture(id: 4))

        #expect(viewModel.state == .success([.fixture(id: 1)]))
        #expect(favorites.ids == [1])
    }

    @Test func failedRemoveKeepsRowAndShowsMessage() async {
        let favorites = StubFavoritesRepository(favorites: [.fixture(id: 4)])
        let viewModel = FavoritesViewModel(favorites: favorites)
        await viewModel.load()
        let error = AppError.persistence("disk full")
        favorites.setSaveError(error)

        await viewModel.remove(.fixture(id: 4))

        #expect(viewModel.state == .success([.fixture(id: 4)]))
        #expect(viewModel.removeErrorMessage == error.localizedDescription)
    }

    // FavoritesView relies on this: a cancelled load returns to .initial (rendered as a spinner),
    // and the next appearance's load completes.
    @Test func cancelledLoadReturnsToInitialAndNextLoadSucceeds() async {
        let viewModel = FavoritesViewModel(favorites: StubFavoritesRepository(favorites: [.fixture(id: 25)]))

        let cancelled = Task { await viewModel.load() }
        cancelled.cancel()
        await cancelled.value
        #expect(viewModel.state == .initial)

        await viewModel.load()
        #expect(viewModel.state == .success([.fixture(id: 25)]))
    }
}
