//
//  PokemonDetail.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 15/08/24.
//

import SwiftUI

struct PokemonDetailView: View {
    @State private var viewModel: PokemonDetailViewModel
    // Bumped on taps only: the flags also change when the screen loads, which shouldn't buzz.
    @State private var tapFeedback = 0

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

                    EvolutionChainView(
                        state: viewModel.evolution,
                        selectedID: viewModel.selectedEvolutionID,
                        currentID: viewModel.pokemonId,
                        type: pokemon.primaryType,
                        onSelect: { id in
                            tapFeedback += 1
                            viewModel.selectEvolution(id)
                        },
                        onRetry: viewModel.loadEvolution
                    )
                }

            case .error(let message):
                ErrorStateView(message: message, onRetry: viewModel.reload)
            }
        }
        .toolbar {
            if case .success = viewModel.state {
                Button {
                    tapFeedback += 1
                    Task { await viewModel.toggleTeam() }
                } label: {
                    Image(
                        systemName: viewModel.isOnTeam
                            ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus")
                }
                .accessibilityLabel(viewModel.isOnTeam ? "Remove from team" : "Add to team")
                .accessibilityIdentifier("team-toggle")

                Button {
                    tapFeedback += 1
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                }
                .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityIdentifier("favorite-toggle")
            }
        }
        .sensoryFeedback(.selection, trigger: tapFeedback)
        .sensoryFeedback(.error, trigger: viewModel.favoriteErrorMessage) { _, new in new != nil }
        .sensoryFeedback(.error, trigger: viewModel.teamErrorMessage) { _, new in new != nil }
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

#if DEBUG
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
#endif
