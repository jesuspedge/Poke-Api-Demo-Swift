import Testing
@testable import Poke_Api_Demo

@MainActor
struct TeamViewModelTests {
    @Test func loadPublishesMembersAndAnalysis() async {
        let members = [PokemonEntity.fixture(id: 4, types: [.fire])]
        let viewModel = TeamViewModel(team: StubTeamRepository(members: members))

        await viewModel.load()

        #expect(viewModel.state == .success(members))
        #expect(viewModel.analysis == TeamAnalysis(team: members))
        #expect(viewModel.canAddMore)
    }

    @Test func emptyTeamCanAddMore() async {
        let viewModel = TeamViewModel(team: StubTeamRepository())

        await viewModel.load()

        #expect(viewModel.state == .success([]))
        #expect(viewModel.canAddMore)
    }

    @Test func fullTeamCannotAddMore() async {
        let viewModel = TeamViewModel(team: StubTeamRepository(members: (1...6).map { PokemonEntity.fixture(id: $0) }))

        await viewModel.load()

        #expect(!viewModel.canAddMore)
    }

    @Test func cannotAddBeforeLoad() {
        #expect(!TeamViewModel(team: StubTeamRepository()).canAddMore)
    }

    @Test func loadPublishesLocalizedErrorMessage() async {
        let team = StubTeamRepository()
        let error = AppError.persistence("corrupt store")
        team.setReadError(error)
        let viewModel = TeamViewModel(team: team)

        await viewModel.load()

        #expect(viewModel.state == .error(error.localizedDescription))
    }

    @Test func removeDropsMember() async {
        let team = StubTeamRepository(members: [.fixture(id: 1), .fixture(id: 4)])
        let viewModel = TeamViewModel(team: team)
        await viewModel.load()

        await viewModel.remove(.fixture(id: 1))

        #expect(viewModel.state == .success([.fixture(id: 4)]))
        #expect(team.ids == [4])
    }

    @Test func failedRemoveKeepsMemberAndShowsMessage() async {
        let team = StubTeamRepository(members: [.fixture(id: 1)])
        let viewModel = TeamViewModel(team: team)
        await viewModel.load()
        let error = AppError.persistence("disk full")
        team.setSaveError(error)

        await viewModel.remove(.fixture(id: 1))

        #expect(viewModel.state == .success([.fixture(id: 1)]))
        #expect(viewModel.removeErrorMessage == error.localizedDescription)
    }

    // TeamView relies on this, like FavoritesView: a cancelled load returns to .initial (a spinner),
    // and the next appearance's load completes.
    @Test func cancelledLoadReturnsToInitialAndNextLoadSucceeds() async {
        let viewModel = TeamViewModel(team: StubTeamRepository(members: [.fixture(id: 25)]))

        let cancelled = Task { await viewModel.load() }
        cancelled.cancel()
        await cancelled.value
        #expect(viewModel.state == .initial)

        await viewModel.load()
        #expect(viewModel.state == .success([.fixture(id: 25)]))
    }
}
