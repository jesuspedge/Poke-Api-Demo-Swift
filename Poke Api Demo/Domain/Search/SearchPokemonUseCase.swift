struct SearchPokemonUseCase: Sendable {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func callAsFunction(query: String, type: PokemonType?) async -> Result<[PokemonSummary], AppError> {
        // The index and the type's members are independent requests, so load them concurrently.
        async let index = repository.getPokemonIndex()
        async let typeIDs = loadTypeIDs(type)
        let (indexResult, typeIDsResult) = await (index, typeIDs)

        return indexResult.flatMap { index in
            typeIDsResult.map { PokemonSearchFilter.filter(index, query: query, typeIDs: $0) }
        }
    }

    private func loadTypeIDs(_ type: PokemonType?) async -> Result<Set<Int>?, AppError> {
        guard let type else { return .success(nil) }
        return await repository.getPokemonIDs(ofType: type).map { Optional($0) }
    }
}
