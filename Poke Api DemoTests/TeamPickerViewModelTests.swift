import Testing
@testable import Poke_Api_Demo

@MainActor
struct TeamPickerViewModelTests {
    private func makeViewModel(
        repository: StubPokemonRepository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1, 4, 25]))),
        team: StubTeamRepository = StubTeamRepository(),
        excludedIDs: Set<Int> = []
    ) -> TeamPickerViewModel {
        TeamPickerViewModel(
            search: SearchPokemonUseCase(repository: repository),
            repository: repository,
            team: team,
            excludedIDs: excludedIDs,
            debounce: .zero
        )
    }

    @Test func resultsLeaveOutCurrentMembers() async {
        let viewModel = makeViewModel(excludedIDs: [4])

        await viewModel.loadResults()

        #expect(viewModel.state == .results(.fixtures(ids: [1, 25])))
    }

    @Test func resultsFollowTheQuery() async {
        let viewModel = makeViewModel()
        await viewModel.loadResults()

        viewModel.query = "25"
        await viewModel.loadResults()

        #expect(viewModel.state == .results(.fixtures(ids: [25])))
    }

    @Test func searchFailurePublishesErrorAndRetryRecovers() async {
        let repository = StubPokemonRepository(indexResult: .failure(.networkError("offline")))
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadResults()
        #expect(viewModel.state == .error(AppError.networkError("offline").localizedDescription))

        repository.setIndexResult(.success(.fixtures(ids: [1])))
        await viewModel.retry()
        #expect(viewModel.state == .results(.fixtures(ids: [1])))
    }

    @Test func pickAddsTheFullPokemonToTheTeam() async {
        let pikachu = PokemonEntity.fixture(id: 25, name: "pikachu", types: [.electric])
        let team = StubTeamRepository()
        let viewModel = makeViewModel(
            repository: StubPokemonRepository(detailResult: .success(pikachu)),
            team: team
        )

        let didAdd = await viewModel.pick(PokemonSummary(id: 25, name: "pikachu"))

        #expect(didAdd)
        #expect(team.ids == [25])
        #expect(viewModel.pickingID == nil)
        #expect(viewModel.pickErrorMessage == nil)
    }

    @Test func failedFetchShowsMessageAndKeepsSheetOpen() async {
        let error = AppError.networkError("offline")
        let team = StubTeamRepository()
        let viewModel = makeViewModel(repository: StubPokemonRepository(detailResult: .failure(error)), team: team)

        let didAdd = await viewModel.pick(PokemonSummary(id: 25, name: "pikachu"))

        #expect(!didAdd)
        #expect(team.ids.isEmpty)
        #expect(viewModel.pickErrorMessage == error.localizedDescription)
    }

    @Test func fullTeamShowsMessage() async {
        let team = StubTeamRepository(members: (1...6).map { PokemonEntity.fixture(id: $0) })
        let viewModel = makeViewModel(
            repository: StubPokemonRepository(detailResult: .success(.fixture(id: 25))),
            team: team
        )

        let didAdd = await viewModel.pick(PokemonSummary(id: 25, name: "pikachu"))

        #expect(!didAdd)
        #expect(viewModel.pickErrorMessage == AppError.teamFull.localizedDescription)
    }
}
