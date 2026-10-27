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

    // MARK: - Search and type filter
    private func makeFilteringViewModel(
        repository: StubPokemonRepository,
        pageSize: Int = 20
    ) -> PokemonListViewModel {
        PokemonListViewModel(repository: repository, pageSize: pageSize, debounce: .zero)
    }

    @Test func filterPagesThroughMatches() async {
        let repository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1, 2, 3, 4, 5])))
        let viewModel = makeFilteringViewModel(repository: repository, pageSize: 2)
        await viewModel.loadIfNeeded()

        viewModel.filter.query = "pokemon"
        await viewModel.loadIfNeeded()
        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2, 3, 4, 5]).pokemons))
        #expect(viewModel.paging == .exhausted)
        #expect(repository.requestedIDBatches == [[1, 2], [3, 4], [5]])
    }

    @Test func typeFilterLoadsOnlyTypeMembers() async {
        let repository = StubPokemonRepository(
            indexResult: .success(.fixtures(ids: [1, 4, 5, 25])),
            typeIDsResult: .success([4, 5])
        )
        let viewModel = makeFilteringViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        viewModel.filter.type = .fire
        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [4, 5]).pokemons))
        #expect(repository.requestedTypes == [.fire])
    }

    @Test func clearingFilterReturnsToBrowsingFromFirstPage() async {
        let repository = StubPokemonRepository(
            listResult: .success(.fixture(ids: [1, 2], nextOffset: 2)),
            indexResult: .success(.fixtures(ids: [25]))
        )
        let viewModel = makeFilteringViewModel(repository: repository)
        await viewModel.loadIfNeeded()
        viewModel.filter.query = "25"
        await viewModel.loadIfNeeded()

        viewModel.filter.query = ""
        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2]).pokemons))
        #expect(repository.requestedOffsets == [0, 0])
    }

    @Test func unchangedFilterDoesNotReload() async {
        let repository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1])))
        let viewModel = makeFilteringViewModel(repository: repository)
        viewModel.filter.query = "pokemon"
        await viewModel.loadIfNeeded()

        viewModel.filter.query = "pokemon  "
        await viewModel.loadIfNeeded()

        #expect(repository.indexCallCount == 1)
    }

    @Test func noMatchesShowsEmptyExhaustedList() async {
        let repository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1])))
        let viewModel = makeFilteringViewModel(repository: repository)
        viewModel.filter.query = "missingno"

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .success([]))
        #expect(viewModel.paging == .exhausted)
        #expect(repository.requestedIDBatches.isEmpty)
    }

    @Test func searchErrorShowsErrorAndRetryRecovers() async {
        let error = AppError.networkError("offline")
        let repository = StubPokemonRepository(indexResult: .failure(error))
        let viewModel = makeFilteringViewModel(repository: repository)
        viewModel.filter.query = "pokemon"
        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .error(error.localizedDescription))

        repository.setIndexResult(.success(.fixtures(ids: [7])))
        await viewModel.reload()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [7]).pokemons))
    }

    @Test func matchesPageErrorFailsPagingAndRetryContinues() async {
        let repository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1, 2, 3])))
        let viewModel = makeFilteringViewModel(repository: repository, pageSize: 2)
        viewModel.filter.query = "pokemon"
        await viewModel.loadIfNeeded()

        repository.setIDsError(.httpStatus(500))
        await viewModel.loadNextPage()
        #expect(viewModel.paging == .failed(AppError.httpStatus(500).localizedDescription))

        repository.setIDsError(nil)
        await viewModel.loadNextPage()

        #expect(viewModel.state == .success(PokemonPage.fixture(ids: [1, 2, 3]).pokemons))
        #expect(viewModel.paging == .exhausted)
    }
}
