import Testing

@testable import Poke_Api_Demo

struct SearchPokemonUseCaseTests {
    @Test func searchWithoutTypeNeverLoadsTypeMembers() async throws {
        let repository = StubPokemonRepository(indexResult: .success(.fixtures(ids: [1, 2])))
        let search = SearchPokemonUseCase(repository: repository)

        let matches = try await search(query: "pokemon-2", type: nil).get()

        #expect(matches.map(\.id) == [2])
        #expect(repository.requestedTypes.isEmpty)
    }

    @Test func searchWithTypeIntersectsTypeMembers() async throws {
        let repository = StubPokemonRepository(
            indexResult: .success(.fixtures(ids: [1, 2, 3])),
            typeIDsResult: .success([1, 3])
        )
        let search = SearchPokemonUseCase(repository: repository)

        let matches = try await search(query: "", type: .fire).get()

        #expect(matches.map(\.id) == [1, 3])
        #expect(repository.requestedTypes == [.fire])
    }

    @Test func indexErrorIsReturned() async {
        let repository = StubPokemonRepository(indexResult: .failure(.httpStatus(503)))
        let search = SearchPokemonUseCase(repository: repository)

        let result = await search(query: "pika", type: nil)

        #expect(result == .failure(.httpStatus(503)))
    }

    @Test func typeErrorIsReturned() async {
        let repository = StubPokemonRepository(
            indexResult: .success(.fixtures(ids: [1])),
            typeIDsResult: .failure(.networkError("offline"))
        )
        let search = SearchPokemonUseCase(repository: repository)

        let result = await search(query: "", type: .water)

        #expect(result == .failure(.networkError("offline")))
    }
}
