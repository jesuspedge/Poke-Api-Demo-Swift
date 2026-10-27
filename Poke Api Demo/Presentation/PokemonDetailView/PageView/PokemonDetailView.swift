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
            // .initial must render a real view: .task on an EmptyView never fires.
            case .initial, .loading:
                ProgressView()

            case .success(let pokemon):
                ScrollView {
                    PokemonDetailCard(pokemon: pokemon)
                }

            case .error(let message):
                ErrorStateView(message: message, onRetry: viewModel.reload)
            }
        }
        .toolbar {
            if case .success = viewModel.state {
                Button {
                    Task { await viewModel.toggleTeam() }
                } label: {
                    Image(systemName: viewModel.isOnTeam ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus")
                }
                .accessibilityLabel(viewModel.isOnTeam ? "Remove from team" : "Add to team")

                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                }
                .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .alert(
            "Couldn't Update Favorites",
            isPresented: Binding(
                get: { viewModel.favoriteErrorMessage != nil },
                set: { if !$0 { viewModel.favoriteErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.favoriteErrorMessage ?? "")
        }
        .alert(
            "Couldn't Update Team",
            isPresented: Binding(
                get: { viewModel.teamErrorMessage != nil },
                set: { if !$0 { viewModel.teamErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.teamErrorMessage ?? "")
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

#Preview {
    NavigationStack {
        PokemonDetailView(
            viewModel: PokemonDetailViewModel(
                pokemonId: 1,
                repository: MockPokemonRepository(),
                favorites: MockFavoritesRepository(seedIDs: [1]),
                team: MockTeamRepository()
            )
        )
    }
}
