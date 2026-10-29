import Foundation
import Testing

@testable import Poke_Api_Demo

struct EvolutionChainTests {
    private let branching = EvolutionChain(
        id: 67,
        root: .fixture(
            id: 133, name: "eevee",
            evolvesTo: [
                .fixture(id: 134, name: "vaporeon", method: .item("water-stone")),
                .fixture(id: 135, name: "jolteon", method: .item("thunder-stone")),
            ]))

    @Test func stagesFlattenALinearChain() {
        #expect(EvolutionChain.fixture().stages.map { $0.map(\.species.id) } == [[1], [2], [3]])
    }

    @Test func stagesGroupBranchesAtTheSameDepth() {
        #expect(branching.stages.map { $0.map(\.species.id) } == [[133], [134, 135]])
        #expect(branching.speciesIDs == [133, 134, 135])
    }

    @Test func singleNodeDoesNotEvolve() {
        let chain = EvolutionChain(id: -128, root: .fixture(id: 128, name: "tauros"))

        #expect(!chain.doesEvolve)
        #expect(chain.stages.count == 1)
        #expect(EvolutionChain.fixture().doesEvolve)
    }

    @Test func roundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(branching)

        #expect(try JSONDecoder().decode(EvolutionChain.self, from: data) == branching)
    }
}
