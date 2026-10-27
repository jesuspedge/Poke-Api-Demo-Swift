//
//  ContentView.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import SwiftUI

struct PokemonListView: View {
    @State private var viewModel: PokemonListViewModel
    
    init(viewModel: PokemonListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top) {
                    TypeFilterBar(selection: $viewModel.filter.type)
                }
                .searchable(text: $viewModel.filter.query, prompt: "Search by name or number")
                .navigationTitle("CHOOSE YOUR POKEMON")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Int.self) { pokemonId in
                    PokemonDetailView(
                        viewModel: AppFactory.makeDetailViewModel(pokemonId: pokemonId)
                    )
                }
        }
        .task(id: viewModel.filter) {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .initial:
            EmptyView()

        case .loading:
            ProgressView()

        case .success(let pokemons) where pokemons.isEmpty && viewModel.filter.isActive:
            ContentUnavailableView.search(text: viewModel.filter.query)

        case .success(let pokemons):
            List {
                ForEach(pokemons) { pokemon in
                    ZStack {
                        PokemonCard(pokemon: pokemon)
                        NavigationLink(value: pokemon.id) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    .listRowSeparator(.hidden)
                }

                if viewModel.paging != .exhausted {
                    PagingFooterView(state: viewModel.paging, onRetry: viewModel.loadNextPage)
                        .listRowSeparator(.hidden)
                        // Re-runs after each appended page in case the footer stays on screen.
                        .task(id: pokemons.count) {
                            await viewModel.loadNextPage()
                        }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh()
            }

        case .error(let message):
            ErrorStateView(message: message, onRetry: viewModel.reload)
        }
    }
}

#Preview {
    PokemonListView(
        viewModel: PokemonListViewModel(repository: MockPokemonRepository(), pageSize: 2)
    )
}
