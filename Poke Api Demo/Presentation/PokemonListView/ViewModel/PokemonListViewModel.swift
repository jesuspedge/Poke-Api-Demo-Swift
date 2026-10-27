//
//  PokemonListViewModel.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

import Observation

@Observable
@MainActor
final class PokemonListViewModel {
    var state: PokemonListState = .initial
    var filter = PokemonListFilter()
    private(set) var paging: PagingState = .idle

    // Browsing pages through the server list; a search pages through its matches locally.
    private enum Source {
        case browse
        case matches([PokemonSummary])
    }

    private let repository: PokemonRepository
    private let search: SearchPokemonUseCase
    private let pageSize: Int
    private let debounce: Duration
    private var source: Source = .browse
    private var nextOffset: Int?
    private var appliedFilter: PokemonListFilter?
    // Bumped whenever the list is replaced, so pages that were in flight are dropped.
    private var generation = 0

    init(
        repository: PokemonRepository,
        search: SearchPokemonUseCase? = nil,
        pageSize: Int = 20,
        debounce: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.search = search ?? SearchPokemonUseCase(repository: repository)
        self.pageSize = pageSize
        self.debounce = debounce
    }

    // Loads when the current filter isn't on screen yet. Called from .task(id: filter):
    // a new edit cancels the previous call, which debounces typing.
    func loadIfNeeded() async {
        guard filter.normalized != appliedFilter else { return }

        // Only user edits are debounced; the first load starts right away.
        if appliedFilter != nil {
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
        }

        await reload()
    }

    func reload() async {
        generation += 1
        let currentGeneration = generation
        let requested = filter.normalized
        appliedFilter = requested
        state = .loading
        paging = .idle

        let result = await loadFirstPage(for: requested)

        // A cancelled load forgets the applied filter so the next appearance or edit loads again.
        guard !Task.isCancelled else {
            if currentGeneration == generation { appliedFilter = nil }
            return
        }
        guard currentGeneration == generation else { return }

        switch result {
        case .success(let (source, page)):
            applyFirstPage(page, from: source)
        case .failure(let error):
            state = .error(error.localizedDescription)
        }
    }

    // Pull-to-refresh: keeps the current list on screen until the new first page arrives.
    func refresh() async {
        guard case .success = state else {
            await reload()
            return
        }

        let requested = filter.normalized
        let result = await loadFirstPage(for: requested)
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let (source, page)):
            appliedFilter = requested
            applyFirstPage(page, from: source)
        case .failure(let error):
            paging = .failed(error.localizedDescription)
        }
    }

    func loadNextPage() async {
        guard case .success = state,
              let offset = nextOffset,
              paging != .loading else { return }

        let currentGeneration = generation
        paging = .loading

        let result = await fetchPage(offset: offset, from: source)

        // The list was replaced while this page was loading; the new list owns the paging state.
        guard currentGeneration == generation else { return }

        guard !Task.isCancelled else {
            paging = .idle
            return
        }

        guard case .success(let current) = state else { return }

        switch result {
        case .success(let page):
            let knownIDs = Set(current.map(\.id))
            state = .success(current + page.pokemons.filter { !knownIDs.contains($0.id) })
            nextOffset = page.nextOffset
            paging = page.hasMore ? .idle : .exhausted
        case .failure(let error):
            paging = .failed(error.localizedDescription)
        }
    }

    // MARK: - Helpers
    private func loadFirstPage(for filter: PokemonListFilter) async -> Result<(Source, PokemonPage), AppError> {
        guard filter.isActive else {
            return await fetchPage(offset: 0, from: .browse).map { (.browse, $0) }
        }

        switch await search(query: filter.query, type: filter.type) {
        case .success(let matches):
            let source = Source.matches(matches)
            return await fetchPage(offset: 0, from: source).map { (source, $0) }
        case .failure(let error):
            return .failure(error)
        }
    }

    private func fetchPage(offset: Int, from source: Source) async -> Result<PokemonPage, AppError> {
        switch source {
        case .browse:
            return await repository.getPokemons(offset: offset, limit: pageSize)

        case .matches(let matches):
            let end = min(offset + pageSize, matches.count)
            guard offset < end else {
                return .success(PokemonPage(pokemons: [], nextOffset: nil))
            }

            let ids = matches[offset..<end].map(\.id)
            return await repository.getPokemons(ids: ids).map { pokemons in
                PokemonPage(pokemons: pokemons, nextOffset: end < matches.count ? end : nil)
            }
        }
    }

    private func applyFirstPage(_ page: PokemonPage, from source: Source) {
        generation += 1
        self.source = source
        state = .success(page.pokemons)
        nextOffset = page.nextOffset
        paging = page.hasMore ? .idle : .exhausted
    }
}
