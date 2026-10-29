import SwiftUI

// A Pokémon card that pushes its detail screen, without the List's disclosure chevron.
struct PokemonNavigationRow: View {
    let pokemon: PokemonEntity
    // The card is the zoom source for its detail screen (iOS 18+).
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            PokemonCard(pokemon: pokemon)
                .zoomSource(id: pokemon.id, in: namespace)
            NavigationLink(value: pokemon.id) {
                EmptyView()
            }
            .opacity(0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pokemon-card-\(pokemon.id)")
        .listRowSeparator(.hidden)
    }
}
