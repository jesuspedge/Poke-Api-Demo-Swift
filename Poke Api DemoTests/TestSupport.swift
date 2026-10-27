import Foundation
import os
@testable import Poke_Api_Demo

struct StubHTTPClient: HTTPClient {
    var handler: @Sendable (URL) throws -> (Data, Int)

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let (data, statusCode) = try handler(url)
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

final class StubPokemonRepository: PokemonRepository {
    private let listResult: OSAllocatedUnfairLock<Result<PokemonPage, AppError>>
    private let detailResult: OSAllocatedUnfairLock<Result<PokemonEntity, AppError>>
    private let calls = OSAllocatedUnfairLock(initialState: 0)
    private let offsets = OSAllocatedUnfairLock(initialState: [Int]())
    private let indexResult: OSAllocatedUnfairLock<Result<[PokemonSummary], AppError>>
    private let typeIDsResult: OSAllocatedUnfairLock<Result<Set<Int>, AppError>>
    private let idsError = OSAllocatedUnfairLock<AppError?>(initialState: nil)
    private let idBatches = OSAllocatedUnfairLock(initialState: [[Int]]())
    private let types = OSAllocatedUnfairLock(initialState: [PokemonType]())
    private let indexCalls = OSAllocatedUnfairLock(initialState: 0)

    var callCount: Int { calls.withLock { $0 } }
    var requestedOffsets: [Int] { offsets.withLock { $0 } }
    var requestedIDBatches: [[Int]] { idBatches.withLock { $0 } }
    var requestedTypes: [PokemonType] { types.withLock { $0 } }
    var indexCallCount: Int { indexCalls.withLock { $0 } }

    init(
        listResult: Result<PokemonPage, AppError> = .success(.fixture()),
        detailResult: Result<PokemonEntity, AppError> = .success(.fixture()),
        indexResult: Result<[PokemonSummary], AppError> = .success([]),
        typeIDsResult: Result<Set<Int>, AppError> = .success([])
    ) {
        self.listResult = OSAllocatedUnfairLock(initialState: listResult)
        self.detailResult = OSAllocatedUnfairLock(initialState: detailResult)
        self.indexResult = OSAllocatedUnfairLock(initialState: indexResult)
        self.typeIDsResult = OSAllocatedUnfairLock(initialState: typeIDsResult)
    }

    func setIndexResult(_ result: Result<[PokemonSummary], AppError>) {
        indexResult.withLock { $0 = result }
    }

    // Makes getPokemons(ids:) fail with this error; nil restores the fixtures.
    func setIDsError(_ error: AppError?) {
        idsError.withLock { $0 = error }
    }

    func setListResult(_ result: Result<PokemonPage, AppError>) {
        listResult.withLock { $0 = result }
    }

    func setDetailResult(_ result: Result<PokemonEntity, AppError>) {
        detailResult.withLock { $0 = result }
    }

    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError> {
        calls.withLock { $0 += 1 }
        offsets.withLock { $0.append(offset) }
        return listResult.withLock { $0 }
    }

    func getPokemons(ids: [Int]) async -> Result<[PokemonEntity], AppError> {
        idBatches.withLock { $0.append(ids) }
        if let error = idsError.withLock({ $0 }) {
            return .failure(error)
        }
        return .success(ids.map { .fixture(id: $0, name: "pokemon-\($0)") })
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        calls.withLock { $0 += 1 }
        return detailResult.withLock { $0 }
    }

    func getPokemonIndex() async -> Result<[PokemonSummary], AppError> {
        indexCalls.withLock { $0 += 1 }
        return indexResult.withLock { $0 }
    }

    func getPokemonIDs(ofType type: PokemonType) async -> Result<Set<Int>, AppError> {
        types.withLock { $0.append(type) }
        return typeIDsResult.withLock { $0 }
    }
}

extension [PokemonSummary] {
    static func fixtures(ids: [Int]) -> [PokemonSummary] {
        ids.map { PokemonSummary(id: $0, name: "pokemon-\($0)") }
    }
}

final class StubFavoritesRepository: FavoritesRepository {
    private let stored: OSAllocatedUnfairLock<[PokemonEntity]>
    private let saveError = OSAllocatedUnfairLock<AppError?>(initialState: nil)
    private let readError = OSAllocatedUnfairLock<AppError?>(initialState: nil)
    private let saves = OSAllocatedUnfairLock(initialState: [(Int, Bool)]())

    var savedChanges: [(id: Int, isFavorite: Bool)] { saves.withLock { $0.map { (id: $0.0, isFavorite: $0.1) } } }
    var ids: [Int] { stored.withLock { $0.map(\.id) } }

    init(favorites: [PokemonEntity] = []) {
        stored = OSAllocatedUnfairLock(initialState: favorites)
    }

    func setSaveError(_ error: AppError?) {
        saveError.withLock { $0 = error }
    }

    func setReadError(_ error: AppError?) {
        readError.withLock { $0 = error }
    }

    func favorites() async -> Result<[PokemonEntity], AppError> {
        if let error = readError.withLock({ $0 }) {
            return .failure(error)
        }
        return .success(stored.withLock { $0 })
    }

    func isFavorite(id: Int) async -> Bool {
        stored.withLock { $0.contains { $0.id == id } }
    }

    func setFavorite(_ isFavorite: Bool, for pokemon: PokemonEntity) async -> Result<Void, AppError> {
        if let error = saveError.withLock({ $0 }) {
            return .failure(error)
        }
        saves.withLock { $0.append((pokemon.id, isFavorite)) }
        stored.withLock { favorites in
            favorites.removeAll { $0.id == pokemon.id }
            if isFavorite { favorites.insert(pokemon, at: 0) }
        }
        return .success(())
    }
}

final class StubTeamRepository: TeamRepository {
    private let members: OSAllocatedUnfairLock<[PokemonEntity]>
    private let saveError = OSAllocatedUnfairLock<AppError?>(initialState: nil)
    private let readError = OSAllocatedUnfairLock<AppError?>(initialState: nil)

    var ids: [Int] { members.withLock { $0.map(\.id) } }

    init(members: [PokemonEntity] = []) {
        self.members = OSAllocatedUnfairLock(initialState: members)
    }

    func setSaveError(_ error: AppError?) {
        saveError.withLock { $0 = error }
    }

    func setReadError(_ error: AppError?) {
        readError.withLock { $0 = error }
    }

    func team() async -> Result<[PokemonEntity], AppError> {
        if let error = readError.withLock({ $0 }) {
            return .failure(error)
        }
        return .success(members.withLock { $0 })
    }

    func isOnTeam(id: Int) async -> Bool {
        members.withLock { $0.contains { $0.id == id } }
    }

    func addToTeam(_ pokemon: PokemonEntity) async -> Result<Void, AppError> {
        if let error = saveError.withLock({ $0 }) {
            return .failure(error)
        }
        return members.withLock { members in
            guard !members.contains(where: { $0.id == pokemon.id }) else { return .success(()) }
            guard members.count < TeamAnalysis.maxTeamSize else { return .failure(.teamFull) }
            members.append(pokemon)
            return .success(())
        }
    }

    func removeFromTeam(id: Int) async -> Result<Void, AppError> {
        if let error = saveError.withLock({ $0 }) {
            return .failure(error)
        }
        members.withLock { $0.removeAll { $0.id == id } }
        return .success(())
    }
}

extension Result {
    var failureValue: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}

final class RequestRecorder: Sendable {
    private let urls = OSAllocatedUnfairLock(initialState: [URL]())

    var all: [URL] { urls.withLock { $0 } }

    func record(_ url: URL) {
        urls.withLock { $0.append(url) }
    }
}

extension PokemonPage {
    static func fixture(ids: [Int] = [1], nextOffset: Int? = nil) -> PokemonPage {
        PokemonPage(pokemons: ids.map { .fixture(id: $0, name: "pokemon-\($0)") }, nextOffset: nextOffset)
    }
}

extension PokemonEntity {
    static func fixture(id: Int = 1, name: String = "bulbasaur", types: [PokemonType] = [.grass, .poison]) -> PokemonEntity {
        PokemonEntity(
            id: id,
            name: name,
            abilities: [AbilityEntity(name: "overgrow")],
            heightInMeters: 0.7,
            weightInKg: 6.9,
            artworkURL: URL(string: "https://example.com/\(id).png"),
            stats: [StatEntity(name: "hp", baseStat: 45)],
            types: types
        )
    }
}

enum PokemonJSON {
    static func make(
        id: Int = 1,
        name: String = "bulbasaur",
        types: [String] = ["grass", "poison"],
        artwork: String? = "\"https://example.com/1.png\""
    ) -> Data {
        let typesJSON = types.map { "{\"type\": {\"name\": \"\($0)\"}}" }.joined(separator: ",")
        let json = """
        {
          "id": \(id),
          "name": "\(name)",
          "abilities": [{"ability": {"name": "overgrow"}}, {"ability": {"name": "chlorophyll"}}],
          "height": 7,
          "weight": 69,
          "sprites": {"other": {"official-artwork": {"front_default": \(artwork ?? "null")}}},
          "stats": [{"base_stat": 45, "stat": {"name": "hp"}}, {"base_stat": 49, "stat": {"name": "attack"}}],
          "types": [\(typesJSON)]
        }
        """
        return Data(json.utf8)
    }

    static func page(ids: [Int], next: String? = nil) -> Data {
        let results = ids
            .map { "{\"name\": \"pokemon-\($0)\", \"url\": \"https://pokeapi.co/api/v2/pokemon/\($0)/\"}" }
            .joined(separator: ",")
        let nextJSON = next.map { "\"\($0)\"" } ?? "null"
        return Data("{\"count\": 1302, \"next\": \(nextJSON), \"results\": [\(results)]}".utf8)
    }

    static func typeDetail(ids: [Int]) -> Data {
        let pokemon = ids
            .map { "{\"slot\": 1, \"pokemon\": {\"name\": \"pokemon-\($0)\", \"url\": \"https://pokeapi.co/api/v2/pokemon/\($0)/\"}}" }
            .joined(separator: ",")
        return Data("{\"id\": 10, \"name\": \"fire\", \"pokemon\": [\(pokemon)]}".utf8)
    }

    static func model(
        types: [String] = ["grass", "poison"],
        artwork: String? = "\"https://example.com/1.png\""
    ) throws -> PokemonModel {
        try JSONDecoder().decode(PokemonModel.self, from: make(types: types, artwork: artwork))
    }
}
