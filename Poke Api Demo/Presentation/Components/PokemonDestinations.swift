import SwiftUI

// A push from an evolution chain: there's no card on screen to zoom from.
struct EvolutionLink: Hashable {
    let id: Int
}

extension View {
    // Registered once at each stack's root, so detail screens pushed deeper don't register them again.
    func pokemonDestinations(zoom namespace: Namespace.ID) -> some View {
        navigationDestination(for: Int.self) { pokemonId in
            PokemonDetailView(viewModel: AppFactory.makeDetailViewModel(pokemonId: pokemonId))
                .zoomTransition(sourceID: pokemonId, in: namespace)
        }
        .navigationDestination(for: EvolutionLink.self) { link in
            PokemonDetailView(viewModel: AppFactory.makeDetailViewModel(pokemonId: link.id))
        }
    }
}
