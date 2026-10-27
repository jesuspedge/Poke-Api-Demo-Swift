import Testing
@testable import Poke_Api_Demo

@MainActor
struct PokemonDetailViewModelTests {
    @Test func loadIfNeededPublishesPokemon() async {
        let pokemon = PokemonEntity.fixture(id: 4, name: "charmander")
        let viewModel = PokemonDetailViewModel(
            pokemonId: 4,
            repository: StubPokemonRepository(detailResult: .success(pokemon)),
            favorites: StubFavoritesRepository(),
            team: StubTeamRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(pokemon))
    }

    @Test func loadIfNeededPublishesLocalizedErrorMessage() async {
        let error = AppError.httpStatus(404)
        let viewModel = PokemonDetailViewModel(
            pokemonId: 1,
            repository: StubPokemonRepository(detailResult: .failure(error)),
            favorites: StubFavoritesRepository(),
            team: StubTeamRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func loadIfNeededOnlyFetchesOnce() async {
        let repository = StubPokemonRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository, favorites: StubFavoritesRepository(), team: StubTeamRepository())

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test func reloadRecoversAfterError() async {
        let repository = StubPokemonRepository(detailResult: .failure(.unknown))
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository, favorites: StubFavoritesRepository(), team: StubTeamRepository())
        await viewModel.loadIfNeeded()

        repository.setDetailResult(.success(.fixture()))
        await viewModel.reload()

        #expect(viewModel.state == .success(.fixture()))
    }

    // MARK: - Favorites
    @Test func loadsFavoriteStatus() async {
        let favorites = StubFavoritesRepository(favorites: [.fixture(id: 1)])
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites, team: StubTeamRepository())

        await viewModel.loadIfNeeded()

        #expect(viewModel.isFavorite)
    }

    @Test func toggleFavoritePersistsBothWays() async {
        let favorites = StubFavoritesRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites, team: StubTeamRepository())
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
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites, team: StubTeamRepository())
        await viewModel.loadIfNeeded()

        await viewModel.toggleFavorite()

        #expect(!viewModel.isFavorite)
        #expect(viewModel.favoriteErrorMessage == error.localizedDescription)
    }

    @Test func toggleFavoriteIsNoOpBeforeLoad() async {
        let favorites = StubFavoritesRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: favorites, team: StubTeamRepository())

        await viewModel.toggleFavorite()

        #expect(!viewModel.isFavorite)
        #expect(favorites.savedChanges.isEmpty)
    }

    // MARK: - Team
    private func makeViewModel(team: StubTeamRepository) -> PokemonDetailViewModel {
        PokemonDetailViewModel(pokemonId: 1, repository: StubPokemonRepository(), favorites: StubFavoritesRepository(), team: team)
    }

    @Test func loadsTeamStatus() async {
        let viewModel = makeViewModel(team: StubTeamRepository(members: [.fixture(id: 1)]))

        await viewModel.loadIfNeeded()

        #expect(viewModel.isOnTeam)
    }

    @Test func toggleTeamAddsAndRemoves() async {
        let team = StubTeamRepository()
        let viewModel = makeViewModel(team: team)
        await viewModel.loadIfNeeded()

        await viewModel.toggleTeam()
        #expect(viewModel.isOnTeam)
        #expect(team.ids == [1])

        await viewModel.toggleTeam()
        #expect(!viewModel.isOnTeam)
        #expect(team.ids.isEmpty)
    }

    @Test func addingToFullTeamRevertsAndShowsMessage() async {
        let team = StubTeamRepository(members: (2...7).map { PokemonEntity.fixture(id: $0) })
        let viewModel = makeViewModel(team: team)
        await viewModel.loadIfNeeded()

        await viewModel.toggleTeam()

        #expect(!viewModel.isOnTeam)
        #expect(viewModel.teamErrorMessage == AppError.teamFull.localizedDescription)
        #expect(team.ids == Array(2...7))
    }

    @Test func toggleTeamIsNoOpBeforeLoad() async {
        let team = StubTeamRepository()
        let viewModel = makeViewModel(team: team)

        await viewModel.toggleTeam()

        #expect(!viewModel.isOnTeam)
        #expect(team.ids.isEmpty)
    }
}
