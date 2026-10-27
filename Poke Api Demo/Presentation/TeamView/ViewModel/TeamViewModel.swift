import Observation

@Observable
@MainActor
final class TeamViewModel {
    var state: TeamState = .initial
    var removeErrorMessage: String?

    private let team: TeamRepository

    init(team: TeamRepository) {
        self.team = team
    }

    var members: [PokemonEntity] {
        guard case .success(let members) = state else { return [] }
        return members
    }

    var analysis: TeamAnalysis { TeamAnalysis(team: members) }

    var canAddMore: Bool {
        guard case .success(let members) = state else { return false }
        return members.count < TeamAnalysis.maxTeamSize
    }

    // Runs on every appearance, since the team changes on other screens.
    // Only the first load shows the spinner; later loads update the team in place.
    func load() async {
        if state == .initial {
            state = .loading
        }

        let result = await team.team()
        guard !Task.isCancelled else {
            if state == .loading { state = .initial }
            return
        }

        switch result {
        case .success(let members):
            state = .success(members)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    func remove(_ pokemon: PokemonEntity) async {
        guard case .success(let members) = state else { return }

        switch await team.removeFromTeam(id: pokemon.id) {
        case .success:
            state = .success(members.filter { $0.id != pokemon.id })
        case .failure(let error):
            removeErrorMessage = error.localizedDescription
        }
    }
}
