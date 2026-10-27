import SwiftUI

// A Pokémon card that pushes its detail screen, without the List's disclosure chevron.
struct PokemonNavigationRow: View {
    let pokemon: PokemonEntity

    var body: some View {
        ZStack {
            PokemonCard(pokemon: pokemon)
            NavigationLink(value: pokemon.id) {
                EmptyView()
            }
            .opacity(0)
        }
        .listRowSeparator(.hidden)
    }
}
