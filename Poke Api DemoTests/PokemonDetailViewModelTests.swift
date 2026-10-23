import Testing
@testable import Poke_Api_Demo

@MainActor
struct PokemonDetailViewModelTests {
    @Test func loadIfNeededPublishesPokemon() async {
        let pokemon = PokemonEntity.fixture(id: 4, name: "charmander")
        let viewModel = PokemonDetailViewModel(
            pokemonId: 4,
            repository: StubPokemonRepository(detailResult: .success(pokemon))
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(pokemon))
    }

    @Test func loadIfNeededPublishesLocalizedErrorMessage() async {
        let error = AppError.httpStatus(404)
        let viewModel = PokemonDetailViewModel(
            pokemonId: 1,
            repository: StubPokemonRepository(detailResult: .failure(error))
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func loadIfNeededOnlyFetchesOnce() async {
        let repository = StubPokemonRepository()
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test func reloadRecoversAfterError() async {
        let repository = StubPokemonRepository(detailResult: .failure(.unknown))
        let viewModel = PokemonDetailViewModel(pokemonId: 1, repository: repository)
        await viewModel.loadIfNeeded()

        repository.setDetailResult(.success(.fixture()))
        await viewModel.reload()

        #expect(viewModel.state == .success(.fixture()))
    }
}
