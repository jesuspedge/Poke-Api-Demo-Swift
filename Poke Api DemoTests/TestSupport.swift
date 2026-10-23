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
    private let listResult: OSAllocatedUnfairLock<Result<[PokemonEntity], AppError>>
    private let detailResult: OSAllocatedUnfairLock<Result<PokemonEntity, AppError>>
    private let calls = OSAllocatedUnfairLock(initialState: 0)

    var callCount: Int { calls.withLock { $0 } }

    init(
        listResult: Result<[PokemonEntity], AppError> = .success([.fixture()]),
        detailResult: Result<PokemonEntity, AppError> = .success(.fixture())
    ) {
        self.listResult = OSAllocatedUnfairLock(initialState: listResult)
        self.detailResult = OSAllocatedUnfairLock(initialState: detailResult)
    }

    func setListResult(_ result: Result<[PokemonEntity], AppError>) {
        listResult.withLock { $0 = result }
    }

    func setDetailResult(_ result: Result<PokemonEntity, AppError>) {
        detailResult.withLock { $0 = result }
    }

    func getPokemons() async -> Result<[PokemonEntity], AppError> {
        calls.withLock { $0 += 1 }
        return listResult.withLock { $0 }
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        calls.withLock { $0 += 1 }
        return detailResult.withLock { $0 }
    }
}

extension PokemonEntity {
    static func fixture(id: Int = 1, name: String = "bulbasaur") -> PokemonEntity {
        PokemonEntity(
            id: id,
            name: name,
            abilities: [AbilityEntity(name: "overgrow")],
            heightInMeters: 0.7,
            weightInKg: 6.9,
            artworkURL: URL(string: "https://example.com/\(id).png"),
            stats: [StatEntity(name: "hp", baseStat: 45)],
            types: [.grass, .poison]
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

    static func model(
        types: [String] = ["grass", "poison"],
        artwork: String? = "\"https://example.com/1.png\""
    ) throws -> PokemonModel {
        try JSONDecoder().decode(PokemonModel.self, from: make(types: types, artwork: artwork))
    }
}
