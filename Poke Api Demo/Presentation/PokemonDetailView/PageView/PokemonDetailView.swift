//
//  PokemonDetail.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 15/08/24.
//

import SwiftUI

struct PokemonDetailView: View {
    @State private var viewModel: PokemonDetailViewModel
    
    init(viewModel: PokemonDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .initial:
                EmptyView()
                
            case .loading:
                ProgressView()

            case .success(let pokemon):
                ScrollView {
                    PokemonDetailCard(pokemon: pokemon)
                }

            case .error(let message):
                ErrorStateView(message: message, onRetry: viewModel.reload)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

#Preview {
    PokemonDetailView(
        viewModel: PokemonDetailViewModel(pokemonId: 1, repository: MockPokemonRepository())
    )
}
