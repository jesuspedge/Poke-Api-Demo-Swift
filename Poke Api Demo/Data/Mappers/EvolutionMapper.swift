import Foundation

struct EvolutionMapper {
    // The same official-artwork URL the /pokemon endpoint returns, so members need no extra request.
    static func artworkURL(forSpeciesID id: Int) -> URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }

    func toEvolutionChain(_ model: EvolutionChainModel) -> EvolutionChain {
        EvolutionChain(id: model.id, root: toNode(model.chain))
    }

    // A species without a chain evolves from and into nothing.
    func singleStageChain(for species: PokemonSpeciesModel) -> EvolutionChain {
        let summary = PokemonSummary(id: species.id, name: species.name)
        let node = EvolutionNode(
            species: summary,
            artworkURL: Self.artworkURL(forSpeciesID: species.id),
            method: nil,
            evolvesTo: []
        )
        // Chain ids are positive, so a negative id can't clash with a real chain.
        return EvolutionChain(id: -species.id, root: node)
    }

    // The first link has no evolution details, so its method is nil.
    // Some species list several ways to evolve (Leafeon: a location, then a Leaf Stone);
    // prefer the first one with a specific method.
    private func toNode(_ link: ChainLinkModel) -> EvolutionNode {
        let methods = link.evolutionDetails.map(toMethod)
        let id = link.species.id ?? 0
        return EvolutionNode(
            species: PokemonSummary(id: id, name: link.species.name),
            artworkURL: Self.artworkURL(forSpeciesID: id),
            method: methods.first(where: \.isSpecific) ?? methods.first,
            evolvesTo: link.evolvesTo.map(toNode)
        )
    }

    private func toMethod(_ detail: EvolutionDetailModel) -> EvolutionMethod {
        switch detail.trigger.name {
        case "level-up":
            if let level = detail.minLevel { return .level(level) }
            if detail.minHappiness != nil { return .friendship }
            return .other(detail.trigger.name)
        case "use-item":
            return detail.item.map { .item($0.name) } ?? .other(detail.trigger.name)
        case "trade":
            return .trade(heldItem: detail.heldItem?.name)
        default:
            return .other(detail.trigger.name)
        }
    }
}

private extension EvolutionMethod {
    var isSpecific: Bool {
        if case .other = self { return false }
        return true
    }
}
