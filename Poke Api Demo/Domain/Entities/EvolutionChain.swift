import Foundation

// Codable so the store can save a whole chain as one JSON payload.
struct EvolutionChain: Hashable, Sendable, Codable {
    let id: Int
    let root: EvolutionNode

    /// The tree flattened by depth: Eevee's chain is [[eevee], [vaporeon, jolteon, ...]].
    var stages: [[EvolutionNode]] {
        var stages: [[EvolutionNode]] = []
        var current = [root]
        while !current.isEmpty {
            stages.append(current)
            current = current.flatMap(\.evolvesTo)
        }
        return stages
    }

    var speciesIDs: [Int] { stages.flatMap { $0.map(\.species.id) } }

    var doesEvolve: Bool { !root.evolvesTo.isEmpty }
}

struct EvolutionNode: Hashable, Sendable, Codable {
    let species: PokemonSummary
    let artworkURL: URL?
    // How this stage is reached from the previous one; nil for the first stage.
    let method: EvolutionMethod?
    let evolvesTo: [EvolutionNode]
}

enum EvolutionMethod: Hashable, Sendable, Codable {
    case level(Int)
    case item(String)
    case trade(heldItem: String?)
    case friendship
    // Any other trigger, by its API name ("shed", "spin", "level-up" with no level...)
    case other(String)
}
