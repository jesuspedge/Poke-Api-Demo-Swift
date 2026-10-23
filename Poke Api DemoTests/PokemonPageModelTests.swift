import Foundation
import Testing
@testable import Poke_Api_Demo

struct PokemonPageModelTests {
    @Test(arguments: [
        ("https://pokeapi.co/api/v2/pokemon/25/", 25),
        ("https://pokeapi.co/api/v2/pokemon/10001", 10001)
    ])
    func idIsParsedFromResourceURL(url: String, expectedID: Int) {
        #expect(NamedResourceModel(name: "pokemon", url: url).id == expectedID)
    }

    @Test func malformedURLHasNoID() {
        #expect(NamedResourceModel(name: "pokemon", url: "https://pokeapi.co/api/v2/pokemon/").id == nil)
        #expect(NamedResourceModel(name: "pokemon", url: "").id == nil)
    }

    @Test func pageDecodes() throws {
        let model = try JSONDecoder().decode(PokemonPageModel.self, from: PokemonJSON.page(ids: [1, 2], next: "next"))

        #expect(model.results.compactMap(\.id) == [1, 2])
        #expect(model.next == "next")
    }
}
