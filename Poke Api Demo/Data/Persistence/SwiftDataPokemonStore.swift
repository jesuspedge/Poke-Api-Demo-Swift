import Foundation
import SwiftData
import os

// The ModelActor owns its ModelContext, so SwiftData work stays off the main actor and Sendable-safe.
@ModelActor
actor SwiftDataPokemonStore {
    private static let logger = Logger(subsystem: "Poke-Api-Demo", category: "Persistence")

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            PokemonRecord.self,
            PokemonSummaryRecord.self,
            TypeMembersRecord.self,
            EvolutionChainRecord.self,
            EvolutionLinkRecord.self,
        ])
        let configuration =
            inMemory
            ? ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    // MARK: - Helpers
    private func record(id: Int) throws -> PokemonRecord? {
        var descriptor = FetchDescriptor<PokemonRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // Updates existing records instead of inserting duplicates: inserting a new object with the
    // same unique id would replace the stored one and lose its favorite flag.
    private func upsert(_ pokemons: [PokemonEntity]) throws -> [Int: PokemonRecord] {
        let ids = pokemons.map(\.id)
        let existing = try modelContext.fetch(
            FetchDescriptor<PokemonRecord>(predicate: #Predicate { ids.contains($0.id) }))
        var recordsByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for pokemon in pokemons {
            if let record = recordsByID[pokemon.id] {
                record.update(from: pokemon)
            } else {
                let record = PokemonRecord(pokemon)
                modelContext.insert(record)
                recordsByID[pokemon.id] = record
            }
        }
        return recordsByID
    }

    private func logFailure(_ action: String, _ error: Error) {
        Self.logger.error("\(action, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - PokemonCache (best effort: failures are logged and treated as cache misses)
extension SwiftDataPokemonStore: PokemonCache {
    func pokemon(id: Int) -> PokemonEntity? {
        do {
            return try record(id: id)?.entity
        } catch {
            logFailure("Reading Pokémon \(id)", error)
            return nil
        }
    }

    func store(_ pokemons: [PokemonEntity]) {
        do {
            _ = try upsert(pokemons)
            try modelContext.save()
        } catch {
            logFailure("Saving Pokémon", error)
        }
    }

    func pokemons(offset: Int, limit: Int) -> [PokemonEntity] {
        var descriptor = FetchDescriptor<PokemonRecord>(sortBy: [SortDescriptor(\.id)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        do {
            return try modelContext.fetch(descriptor).map(\.entity)
        } catch {
            logFailure("Reading saved Pokémon", error)
            return []
        }
    }

    func index() -> [PokemonSummary]? {
        do {
            let records = try modelContext.fetch(FetchDescriptor<PokemonSummaryRecord>(sortBy: [SortDescriptor(\.id)]))
            return records.isEmpty ? nil : records.map(\.summary)
        } catch {
            logFailure("Reading the index", error)
            return nil
        }
    }

    func storeIndex(_ index: [PokemonSummary]) {
        do {
            try modelContext.delete(model: PokemonSummaryRecord.self)
            for summary in index {
                modelContext.insert(PokemonSummaryRecord(summary))
            }
            try modelContext.save()
        } catch {
            logFailure("Saving the index", error)
        }
    }

    func pokemonIDs(ofType type: PokemonType) -> Set<Int>? {
        let typeName = type.rawValue
        do {
            let descriptor = FetchDescriptor<TypeMembersRecord>(predicate: #Predicate { $0.typeName == typeName })
            return try modelContext.fetch(descriptor).first.map { Set($0.ids) }
        } catch {
            logFailure("Reading \(typeName) members", error)
            return nil
        }
    }

    func storePokemonIDs(_ ids: Set<Int>, ofType type: PokemonType) {
        let typeName = type.rawValue
        do {
            let descriptor = FetchDescriptor<TypeMembersRecord>(predicate: #Predicate { $0.typeName == typeName })
            if let record = try modelContext.fetch(descriptor).first {
                record.ids = ids.sorted()
            } else {
                modelContext.insert(TypeMembersRecord(typeName: typeName, ids: ids.sorted()))
            }
            try modelContext.save()
        } catch {
            logFailure("Saving \(typeName) members", error)
        }
    }

    func evolutionChain(speciesID: Int) -> EvolutionChain? {
        do {
            var linkDescriptor = FetchDescriptor<EvolutionLinkRecord>(
                predicate: #Predicate { $0.speciesID == speciesID })
            linkDescriptor.fetchLimit = 1
            guard let chainID = try modelContext.fetch(linkDescriptor).first?.chainID else { return nil }

            var chainDescriptor = FetchDescriptor<EvolutionChainRecord>(predicate: #Predicate { $0.id == chainID })
            chainDescriptor.fetchLimit = 1
            guard let payload = try modelContext.fetch(chainDescriptor).first?.payload else { return nil }
            return try JSONDecoder().decode(EvolutionChain.self, from: payload)
        } catch {
            logFailure("Reading the evolution chain of \(speciesID)", error)
            return nil
        }
    }

    func storeEvolutionChain(_ chain: EvolutionChain) {
        let chainID = chain.id
        let speciesIDs = chain.speciesIDs
        do {
            let payload = try JSONEncoder().encode(chain)
            let existing = try modelContext.fetch(
                FetchDescriptor<EvolutionChainRecord>(predicate: #Predicate { $0.id == chainID }))
            if let record = existing.first {
                record.payload = payload
            } else {
                modelContext.insert(EvolutionChainRecord(id: chainID, payload: payload))
            }

            let links = try modelContext.fetch(
                FetchDescriptor<EvolutionLinkRecord>(predicate: #Predicate { speciesIDs.contains($0.speciesID) }))
            let linksBySpecies = Dictionary(uniqueKeysWithValues: links.map { ($0.speciesID, $0) })
            for speciesID in speciesIDs {
                if let link = linksBySpecies[speciesID] {
                    link.chainID = chainID
                } else {
                    modelContext.insert(EvolutionLinkRecord(speciesID: speciesID, chainID: chainID))
                }
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            logFailure("Saving evolution chain \(chainID)", error)
        }
    }
}

// MARK: - FavoritesRepository
extension SwiftDataPokemonStore: FavoritesRepository {
    func favorites() -> Result<[PokemonEntity], AppError> {
        let descriptor = FetchDescriptor<PokemonRecord>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )
        do {
            return .success(try modelContext.fetch(descriptor).map(\.entity))
        } catch {
            logFailure("Reading favorites", error)
            return .failure(.persistence(error.localizedDescription))
        }
    }

    func isFavorite(id: Int) -> Bool {
        do {
            return try record(id: id)?.isFavorite ?? false
        } catch {
            logFailure("Reading favorite \(id)", error)
            return false
        }
    }

    func setFavorite(_ isFavorite: Bool, for pokemon: PokemonEntity) -> Result<Void, AppError> {
        do {
            // Upserting keeps favorites working even for a Pokémon that was never cached.
            let record = try upsert([pokemon])[pokemon.id]
            record?.isFavorite = isFavorite
            record?.favoritedAt = isFavorite ? .now : nil
            try modelContext.save()
            return .success(())
        } catch {
            modelContext.rollback()
            logFailure("Saving favorite \(pokemon.id)", error)
            return .failure(.persistence(error.localizedDescription))
        }
    }
}

// MARK: - TeamRepository
extension SwiftDataPokemonStore: TeamRepository {
    func team() -> Result<[PokemonEntity], AppError> {
        let descriptor = FetchDescriptor<PokemonRecord>(
            predicate: #Predicate { $0.teamAddedAt != nil },
            sortBy: [SortDescriptor(\.teamAddedAt)]
        )
        do {
            return .success(try modelContext.fetch(descriptor).map(\.entity))
        } catch {
            logFailure("Reading the team", error)
            return .failure(.persistence(error.localizedDescription))
        }
    }

    func isOnTeam(id: Int) -> Bool {
        do {
            return try record(id: id)?.teamAddedAt != nil
        } catch {
            logFailure("Reading team member \(id)", error)
            return false
        }
    }

    func addToTeam(_ pokemon: PokemonEntity) -> Result<Void, AppError> {
        do {
            if try record(id: pokemon.id)?.teamAddedAt != nil { return .success(()) }

            // Counted inside the actor, so two quick adds can't push the team past the limit.
            let members = try modelContext.fetchCount(
                FetchDescriptor<PokemonRecord>(predicate: #Predicate { $0.teamAddedAt != nil }))
            guard members < TeamAnalysis.maxTeamSize else { return .failure(.teamFull) }

            try upsert([pokemon])[pokemon.id]?.teamAddedAt = .now
            try modelContext.save()
            return .success(())
        } catch {
            modelContext.rollback()
            logFailure("Adding team member \(pokemon.id)", error)
            return .failure(.persistence(error.localizedDescription))
        }
    }

    func removeFromTeam(id: Int) -> Result<Void, AppError> {
        do {
            try record(id: id)?.teamAddedAt = nil
            try modelContext.save()
            return .success(())
        } catch {
            modelContext.rollback()
            logFailure("Removing team member \(id)", error)
            return .failure(.persistence(error.localizedDescription))
        }
    }
}
