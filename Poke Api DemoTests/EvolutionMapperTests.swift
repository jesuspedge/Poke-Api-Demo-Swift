import Foundation
import Testing

@testable import Poke_Api_Demo

struct EvolutionMapperTests {
    private let mapper = EvolutionMapper()

    private func map(_ data: Data) throws -> EvolutionChain {
        mapper.toEvolutionChain(try JSONDecoder().decode(EvolutionChainModel.self, from: data))
    }

    @Test func linearChainKeepsStagesLevelsAndArtwork() throws {
        let chain = try map(PokemonJSON.bulbasaurChain())

        #expect(chain == .fixture())
        #expect(chain.root.method == nil)
        #expect(
            chain.root.artworkURL?.absoluteString
                == "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"
        )
    }

    @Test func branchingChainMapsEachBranchsMethod() throws {
        let data = PokemonJSON.evolutionChain(
            id: 67,
            chain: PokemonJSON.chainLink(
                id: 133, name: "eevee",
                evolvesTo: [
                    PokemonJSON.chainLink(
                        id: 134, name: "vaporeon",
                        details: [PokemonJSON.detail(trigger: "use-item", item: "water-stone")]),
                    PokemonJSON.chainLink(
                        id: 196, name: "espeon", details: [PokemonJSON.detail(trigger: "level-up", minHappiness: 160)]),
                ]))

        let chain = try map(data)

        #expect(chain.stages.map { $0.map(\.species.name) } == [["eevee"], ["vaporeon", "espeon"]])
        #expect(chain.stages[1].map(\.method) == [.item("water-stone"), .friendship])
    }

    @Test(arguments: [
        (PokemonJSON.detail(trigger: "trade", heldItem: "metal-coat"), EvolutionMethod.trade(heldItem: "metal-coat")),
        (PokemonJSON.detail(trigger: "trade"), .trade(heldItem: nil)),
        (PokemonJSON.detail(trigger: "shed"), .other("shed")),
        (PokemonJSON.detail(trigger: "level-up"), .other("level-up")),
        // A level beats friendship when both are set.
        (PokemonJSON.detail(trigger: "level-up", minLevel: 20, minHappiness: 220), .level(20)),
    ])
    func triggersMapToMethods(detail: String, expected: EvolutionMethod) throws {
        let data = PokemonJSON.evolutionChain(
            id: 46,
            chain: PokemonJSON.chainLink(
                id: 95, name: "onix",
                evolvesTo: [
                    PokemonJSON.chainLink(id: 208, name: "steelix", details: [detail])
                ]))

        #expect(try map(data).stages[1].first?.method == expected)
    }

    @Test func specificMethodIsPreferredOverAGenericOne() throws {
        let data = PokemonJSON.evolutionChain(
            id: 67,
            chain: PokemonJSON.chainLink(
                id: 133, name: "eevee",
                evolvesTo: [
                    PokemonJSON.chainLink(
                        id: 470, name: "leafeon",
                        details: [
                            PokemonJSON.detail(trigger: "level-up"),
                            PokemonJSON.detail(trigger: "use-item", item: "leaf-stone"),
                        ])
                ]))

        #expect(try map(data).stages[1].first?.method == .item("leaf-stone"))
    }

    @Test func speciesWithoutChainBecomesASingleStage() {
        let species = PokemonSpeciesModel(id: 128, name: "tauros", evolutionChain: nil)

        let chain = mapper.singleStageChain(for: species)

        #expect(!chain.doesEvolve)
        #expect(chain.speciesIDs == [128])
    }
}
