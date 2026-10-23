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
    private(set) var paging: PagingState = .idle

    private let repository: PokemonRepository
    private let pageSize: Int
    private var nextOffset: Int?

    init(repository: PokemonRepository, pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func loadIfNeeded() async {
        guard state == .initial else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        paging = .idle

        let result = await repository.getPokemons(offset: 0, limit: pageSize)

        // A cancelled .task resets the state so the next appearance loads again.
        guard !Task.isCancelled else {
            state = .initial
            return
        }

        switch result {
        case .success(let page):
            applyFirstPage(page)
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

        let result = await repository.getPokemons(offset: 0, limit: pageSize)
        guard !Task.isCancelled else { return }

        switch result {
        case .success(let page):
            applyFirstPage(page)
        case .failure(let error):
            paging = .failed(error.localizedDescription)
        }
    }

    func loadNextPage() async {
        guard case .success = state,
              let offset = nextOffset,
              paging != .loading else { return }

        paging = .loading

        let result = await repository.getPokemons(offset: offset, limit: pageSize)

        guard !Task.isCancelled else {
            paging = .idle
            return
        }

        // A refresh finished while this page was loading and moved the offset; drop the stale page.
        guard offset == nextOffset, case .success(let current) = state else { return }

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

    private func applyFirstPage(_ page: PokemonPage) {
        state = .success(page.pokemons)
        nextOffset = page.nextOffset
        paging = page.hasMore ? .idle : .exhausted
    }
}
