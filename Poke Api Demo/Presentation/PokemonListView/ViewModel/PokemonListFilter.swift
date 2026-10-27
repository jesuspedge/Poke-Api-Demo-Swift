import Foundation

struct PokemonListFilter: Hashable {
    var query = ""
    var type: PokemonType?

    var isActive: Bool { normalized.query.isEmpty == false || type != nil }

    // "pika " and "pika" are the same search, so they shouldn't trigger a second load.
    var normalized: PokemonListFilter {
        PokemonListFilter(query: query.trimmingCharacters(in: .whitespacesAndNewlines), type: type)
    }
}
