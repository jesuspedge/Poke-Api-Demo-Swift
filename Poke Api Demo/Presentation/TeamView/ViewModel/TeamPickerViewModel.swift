import Observation

@Observable
@MainActor
final class TeamPickerViewModel {
    var query = ""
    var pickErrorMessage: String?
    private(set) var state: TeamPickerState = .loading
    // The Pokémon being fetched and added, so its row can show a spinner.
    private(set) var pickingID: Int?

    private let search: SearchPokemonUseCase
    private let repository: PokemonRepository
    private let team: TeamRepository
    private let excludedIDs: Set<Int>
    private let debounce: Duration
    private var hasLoaded = false

    init(
        search: SearchPokemonUseCase,
        repository: PokemonRepository,
        team: TeamRepository,
        excludedIDs: Set<Int>,
        debounce: Duration = .milliseconds(300)
    ) {
        self.search = search
        self.repository = repository
        self.team = team
        self.excludedIDs = excludedIDs
        self.debounce = debounce
    }

    // Called from .task(id: query): a new edit cancels the previous call, which debounces typing.
    func loadResults() async {
        if hasLoaded {
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
        }

        let result = await search(query: query, type: nil)
        guard !Task.isCancelled else { return }
        hasLoaded = true

        switch result {
        case .success(let matches):
            state = .results(matches.filter { !excludedIDs.contains($0.id) })
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    func retry() async {
        state = .loading
        await loadResults()
    }

    /// Fetches the full Pokémon and adds it to the team. Returns true when the sheet can close.
    func pick(_ summary: PokemonSummary) async -> Bool {
        guard pickingID == nil else { return false }
        pickingID = summary.id
        defer { pickingID = nil }

        let result = await repository.getPokemon(id: summary.id)
        switch result {
        case .success(let pokemon):
            if case .failure(let error) = await team.addToTeam(pokemon) {
                pickErrorMessage = error.localizedDescription
                return false
            }
            return true
        case .failure(let error):
            pickErrorMessage = error.localizedDescription
            return false
        }
    }
}
