//
//  ContentView.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import SwiftUI

struct PokemonListView: View {
    let viewModel: PokemonListViewModel
    
    init(viewModel: PokemonListViewModel) {
        self.viewModel = viewModel
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
                            NavigationLink(destination: PokemonDetail(pokemon: pokemon)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)

                case .error(let message):
                    VStack {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .frame(maxWidth: 50, maxHeight: 50)
                            .padding(.bottom, 30)
                        Text("Something went wrong")
                            .font(.title2)
                            .padding(.bottom, 10)
                        Text(message)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .navigationTitle("CHOOSE YOUR POKEMON")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .onAppear {
            Task { await viewModel.fetchPokemons() }
        }
    }
}

#Preview {
    PokemonListView(
        viewModel: PokemonListViewModel(repository: MockPokemonRepository())
    )
}
