enum EvolutionState: Equatable {
    case loading
    case loaded(EvolutionChain)
    case failed(String)
}
