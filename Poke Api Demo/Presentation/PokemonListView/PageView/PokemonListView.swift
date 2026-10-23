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
            Group {
                switch viewModel.state {
                case .initial:
                    EmptyView()

                case .loading:
                    ProgressView()

                case .success(let pokemons):
                    List(pokemons) { pokemon in
                        ZStack {
                            PokemonCard(pokemon: pokemon)
                            NavigationLink(value: pokemon.id) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)

                case .error(let message):
                    ErrorStateView(message: message, onRetry: viewModel.reload)
                }
            }
            .navigationTitle("CHOOSE YOUR POKEMON")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Int.self) { pokemonId in
                PokemonDetailView(
                    viewModel: AppFactory.makeDetailViewModel(pokemonId: pokemonId)
                )
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

#Preview {
    PokemonListView(
        viewModel: PokemonListViewModel(repository: MockPokemonRepository())
    )
}
