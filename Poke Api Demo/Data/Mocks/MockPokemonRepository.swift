import Foundation

// MARK: - Mock (Debug / Preview only)
#if DEBUG
private extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        guard let url = self.url(forResource: filename, withExtension: "json") else {
            throw AppError.decodingError("Fixture file '\(filename).json' not found in bundle")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct MockPokemonRepository: PokemonRepository {
    private let mapper = PokemonMapper()
    private let fixtureIDs = [1, 2, 3, 4, 5]

    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError> {
        loadFixtures(ids: Array(fixtureIDs.dropFirst(offset).prefix(limit))).map { entities in
            let nextOffset = offset + entities.count
            return PokemonPage(
                pokemons: entities,
                nextOffset: nextOffset < fixtureIDs.count ? nextOffset : nil
            )
        }
    }

    func getPokemons(ids: [Int]) async -> Result<[PokemonEntity], AppError> {
        loadFixtures(ids: ids)
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        loadFixtures(ids: [id]).map { $0[0] }
    }

    func getPokemonIndex() async -> Result<[PokemonSummary], AppError> {
        loadFixtures(ids: fixtureIDs).map { entities in
            entities.map { PokemonSummary(id: $0.id, name: $0.name) }
        }
    }

    func getPokemonIDs(ofType type: PokemonType) async -> Result<Set<Int>, AppError> {
        loadFixtures(ids: fixtureIDs).map { entities in
            Set(entities.filter { $0.types.contains(type) }.map(\.id))
        }
    }

    private func loadFixtures(ids: [Int]) -> Result<[PokemonEntity], AppError> {
        do {
            return .success(try ids.map {
                let model = try Bundle.main.decode(PokemonModel.self, from: "pokemon_\($0)")
                return mapper.toPokemonEntity(model)
            })
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
}
#endif
