//
//  ApiNetwork.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

struct PokemonRemoteSource: PokemonRepository {
    private let apiRoot = "https://pokeapi.co/api/v2"
    // Larger than the dex, so a single request returns every name.
    private let indexLimit = 100_000
    // Default forms share their species id; alternate forms (megas, regional forms...) start at 10001.
    private let firstAlternateFormID = 10_001
    private let mapper = PokemonMapper()
    private let evolutionMapper = EvolutionMapper()
    private let client: HTTPClient
    private let decoder: JSONDecoder
    private let cache: PokemonCache

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        cache: PokemonCache = InMemoryPokemonCache()
    ) {
        self.client = client
        self.decoder = decoder
        self.cache = cache
    }

    func getPokemons(offset: Int, limit: Int) async -> Result<PokemonPage, AppError> {
        do {
            let page: PokemonPageModel = try await get(try listURL(offset: offset, limit: limit))
            let pokemons = try await fetchPokemons(ids: page.results.compactMap(\.id))

            let nextOffset = page.next == nil ? nil : offset + page.results.count
            return .success(PokemonPage(pokemons: pokemons, nextOffset: nextOffset))

        } catch {
            let appError = mapError(error)
            if case .networkError = appError, let savedPage = await savedPage(offset: offset, limit: limit) {
                return .success(savedPage)
            }
            return .failure(appError)
        }
    }

    func getPokemons(ids: [Int]) async -> Result<[PokemonEntity], AppError> {
        do {
            return .success(try await fetchPokemons(ids: ids))
        } catch {
            return .failure(mapError(error))
        }
    }

    func getPokemon(id: Int) async -> Result<PokemonEntity, AppError> {
        do {
            return .success(try await fetchPokemon(id: id))
        } catch {
            return .failure(mapError(error))
        }
    }

    func getPokemonIndex() async -> Result<[PokemonSummary], AppError> {
        if let cached = await cache.index() {
            return .success(cached)
        }

        do {
            let page: PokemonPageModel = try await get(try listURL(offset: 0, limit: indexLimit))
            let index = page.results.compactMap { result in
                result.id.map { PokemonSummary(id: $0, name: result.name) }
            }
            await cache.storeIndex(index)
            return .success(index)
        } catch {
            return .failure(mapError(error))
        }
    }

    func getPokemonIDs(ofType type: PokemonType) async -> Result<Set<Int>, AppError> {
        if let cached = await cache.pokemonIDs(ofType: type) {
            return .success(cached)
        }

        do {
            guard let url = URL(string: "\(apiRoot)/type/\(type.rawValue)") else {
                throw AppError.invalidURL
            }
            let model: TypeDetailModel = try await get(url)
            let ids = Set(model.pokemon.compactMap(\.pokemon.id))
            await cache.storePokemonIDs(ids, ofType: type)
            return .success(ids)
        } catch {
            return .failure(mapError(error))
        }
    }

    func getEvolutionChain(pokemonID: Int) async -> Result<EvolutionChain, AppError> {
        do {
            let speciesID = try await speciesID(forPokemonID: pokemonID)
            if let cached = await cache.evolutionChain(speciesID: speciesID) {
                return .success(cached)
            }

            let species: PokemonSpeciesModel = try await get(try resourceURL("pokemon-species", id: speciesID))
            let chain: EvolutionChain
            if let chainURL = species.evolutionChain.flatMap({ URL(string: $0.url) }) {
                chain = evolutionMapper.toEvolutionChain(try await get(chainURL))
            } else {
                chain = evolutionMapper.singleStageChain(for: species)
            }

            await cache.storeEvolutionChain(chain)
            return .success(chain)
        } catch {
            return .failure(mapError(error))
        }
    }

    // MARK: - Helpers
    private func speciesID(forPokemonID id: Int) async throws -> Int {
        guard id >= firstAlternateFormID else { return id }

        let link: PokemonSpeciesLinkModel = try await get(try resourceURL("pokemon", id: id))
        guard let speciesID = link.species.id else {
            throw AppError.decodingError("Missing species id for Pokémon \(id)")
        }
        return speciesID
    }

    // Offline fallback: pages through the Pokémon saved on this device.
    private func savedPage(offset: Int, limit: Int) async -> PokemonPage? {
        let saved = await cache.pokemons(offset: offset, limit: limit)
        guard !saved.isEmpty else { return nil }
        return PokemonPage(
            pokemons: saved,
            nextOffset: saved.count == limit ? offset + limit : nil,
            isOffline: true
        )
    }

    private func fetchPokemons(ids: [Int]) async throws -> [PokemonEntity] {
        try await withThrowingTaskGroup(of: (Int, PokemonEntity).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { (index, try await fetchPokemon(id: id)) }
            }

            // Keep the caller's order: ids jump to 10001+ near the end of the dex.
            var indexed: [(Int, PokemonEntity)] = []
            for try await result in group {
                indexed.append(result)
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func fetchPokemon(id: Int) async throws -> PokemonEntity {
        if let cached = await cache.pokemon(id: id) {
            return cached
        }

        let model: PokemonModel = try await get(try resourceURL("pokemon", id: id))
        let pokemon = mapper.toPokemonEntity(model)
        await cache.store([pokemon])
        return pokemon
    }

    private func resourceURL(_ resource: String, id: Int) throws -> URL {
        guard let url = URL(string: "\(apiRoot)/\(resource)/\(id)") else {
            throw AppError.invalidURL
        }
        return url
    }

    private func listURL(offset: Int, limit: Int) throws -> URL {
        var components = URLComponents(string: "\(apiRoot)/pokemon")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        guard let url = components?.url else {
            throw AppError.invalidURL
        }
        return url
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await client.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw AppError.httpStatus(httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func mapError(_ error: Error) -> AppError {
        switch error {
        case let appError as AppError:
            appError
        case is DecodingError:
            .decodingError("Failed to decode Pokemon data")
        default:
            .networkError(error.localizedDescription)
        }
    }
}
