import Testing
@testable import Poke_Api_Demo

@MainActor
struct PokemonListViewModelTests {
    @Test func loadIfNeededPublishesPokemons() async {
        let pokemons = [PokemonEntity.fixture(id: 1), .fixture(id: 2, name: "ivysaur")]
        let viewModel = PokemonListViewModel(repository: StubPokemonRepository(listResult: .success(pokemons)))

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(pokemons))
    }

    @Test func loadIfNeededPublishesLocalizedErrorMessage() async {
        let error = AppError.networkError("offline")
        let viewModel = PokemonListViewModel(repository: StubPokemonRepository(listResult: .failure(error)))

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func loadIfNeededOnlyFetchesOnce() async {
        let repository = StubPokemonRepository()
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.callCount == 1)
    }

    @Test func reloadRecoversAfterError() async {
        let repository = StubPokemonRepository(listResult: .failure(.unknown))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        repository.setListResult(.success([.fixture()]))
        await viewModel.reload()

        #expect(viewModel.state == .success([.fixture()]))
        #expect(repository.callCount == 2)
    }
}
