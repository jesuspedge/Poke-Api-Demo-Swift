import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            PokemonListView(viewModel: AppFactory.makeListViewModel())
                .tabItem { Label("Pokédex", systemImage: "square.grid.2x2") }

            FavoritesView(viewModel: AppFactory.makeFavoritesViewModel())
                .tabItem { Label("Favorites", systemImage: "heart") }
        }
    }
}
