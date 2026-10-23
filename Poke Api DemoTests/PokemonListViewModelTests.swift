import Testing
@testable import Poke_Api_Demo

@MainActor
struct PokemonListViewModelTests {
    @Test func loadIfNeededPublishesPokemons() async {
        let page = PokemonPage.fixture(ids: [1, 2], nextOffset: 2)
        let viewModel = PokemonListViewModel(repository: StubPokemonRepository(listResult: .success(page)))

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(page.pokemons))
        #expect(viewModel.paging == .idle)
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

        repository.setListResult(.success(.fixture()))
        await viewModel.reload()

        #expect(viewModel.state == .success(PokemonPage.fixture().pokemons))
        #expect(repository.callCount == 2)
    }

    @Test func singlePageIsExhausted() async {
        let viewModel = PokemonListViewModel(repository: StubPokemonRepository(listResult: .success(.fixture(nextOffset: nil))))

        await viewModel.loadIfNeeded()

        #expect(viewModel.paging == .exhausted)
    }

    // MARK: - Paging
    @Test func loadNextPageAppendsAndRequestsNextOffset() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1, 2], nextOffset: 2)))
        let viewModel = PokemonListViewModel(repository: repository, pageSize: 2)
        await viewModel.loadIfNeeded()

        repository.setListResult(.success(.fixture(ids: [3, 4], nextOffset: 4)))
        await viewModel.loadNextPage()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2, 3, 4]).pokemons))
        #expect(viewModel.paging == .idle)
        #expect(repository.requestedOffsets == [0, 2])
    }

    @Test func lastPageMarksPagingExhaustedAndStopsRequesting() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1], nextOffset: 1)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        repository.setListResult(.success(.fixture(ids: [2], nextOffset: nil)))
        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        #expect(viewModel.paging == .exhausted)
        #expect(repository.callCount == 2)
    }

    @Test func loadNextPageFailureKeepsListAndCanRetry() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1], nextOffset: 1)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        let error = AppError.httpStatus(500)
        repository.setListResult(.failure(error))
        await viewModel.loadNextPage()

        #expect(viewModel.paging == .failed(error.localizedDescription))
        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1]).pokemons))

        repository.setListResult(.success(.fixture(ids: [2], nextOffset: nil)))
        await viewModel.loadNextPage()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2]).pokemons))
        #expect(repository.requestedOffsets == [0, 1, 1])
    }

    @Test func loadNextPageIsNoOpBeforeFirstPage() async {
        let repository = StubPokemonRepository()
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.loadNextPage()

        #expect(viewModel.state == .initial)
        #expect(repository.callCount == 0)
    }

    @Test func loadNextPageSkipsDuplicateIds() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1, 2], nextOffset: 2)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        repository.setListResult(.success(.fixture(ids: [2, 3], nextOffset: nil)))
        await viewModel.loadNextPage()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2, 3]).pokemons))
    }

    @Test func reloadStartsAgainFromFirstPage() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1], nextOffset: 1)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()
        repository.setListResult(.success(.fixture(ids: [2], nextOffset: 2)))
        await viewModel.loadNextPage()

        repository.setListResult(.success(.fixture(ids: [1], nextOffset: 1)))
        await viewModel.reload()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1]).pokemons))
        #expect(repository.requestedOffsets == [0, 1, 0])
    }

    // MARK: - Refresh
    @Test func refreshReplacesListWithFirstPage() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1], nextOffset: 1)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()
        repository.setListResult(.success(.fixture(ids: [2], nextOffset: 2)))
        await viewModel.loadNextPage()

        repository.setListResult(.success(.fixture(ids: [5], nextOffset: 1)))
        await viewModel.refresh()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [5]).pokemons))
        #expect(repository.requestedOffsets.last == 0)
    }

    @Test func refreshFailureKeepsCurrentList() async {
        let repository = StubPokemonRepository(listResult: .success(.fixture(ids: [1], nextOffset: 1)))
        let viewModel = PokemonListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        let error = AppError.networkError("offline")
        repository.setListResult(.failure(error))
        await viewModel.refresh()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1]).pokemons))
        #expect(viewModel.paging == .failed(error.localizedDescription))
    }
}
