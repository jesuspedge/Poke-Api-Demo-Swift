import SwiftUI

struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel
    @Namespace private var zoom

    init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Inside the stack, so it runs again when popping back from a detail screen.
                .task {
                    await viewModel.load()
                }
                .navigationTitle("FAVORITES")
                .navigationBarTitleDisplayMode(.inline)
                .pokemonDestinations(zoom: zoom)
                .alert(
                    "Couldn't Update Favorites",
                    isPresented: Binding(
                        get: { viewModel.removeErrorMessage != nil },
                        set: { if !$0 { viewModel.removeErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.removeErrorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        // .initial must render a real view: .task on an EmptyView never fires.
        case .initial, .loading:
            ProgressView()

        case .success(let pokemons) where pokemons.isEmpty:
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart",
                description: Text("Tap the heart on a Pokémon to save it here.")
            )

        case .success(let pokemons):
            List(pokemons) { pokemon in
                PokemonNavigationRow(pokemon: pokemon, namespace: zoom)
                    .swipeActions {
                        Button("Remove", systemImage: "heart.slash", role: .destructive) {
                            Task { await viewModel.remove(pokemon) }
                        }
                    }
            }
            .listStyle(.plain)

        case .error(let message):
            ErrorStateView(message: message, onRetry: viewModel.load)
        }
    }
}

#if DEBUG
#Preview {
    FavoritesView(
        viewModel: FavoritesViewModel(favorites: MockFavoritesRepository(seedIDs: [4, 1]))
    )
}
#endif
