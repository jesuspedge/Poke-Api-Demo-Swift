//
//  PokemonDetail.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 15/08/24.
//

import SwiftUI

struct PokemonDetailView: View {
    let viewModel: PokemonDetailViewModel
    let pokemonId: Int
    
    init(viewModel: PokemonDetailViewModel, pokemonId: Int) {
        self.viewModel = viewModel
        self.pokemonId = pokemonId
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                EmptyView()
                
            case .loading:
                ProgressView()

            case .success(let pokemon):
                PokemonDetailCard(pokemon: pokemon)

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
        .onAppear {
            Task { await viewModel.fetchPokemon(id: pokemonId) }
        }
    }
}

#Preview {
    PokemonDetailView(viewModel: AppFactory.makeDetailViewModel(), pokemonId: 1)
}
