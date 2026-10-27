import Testing
@testable import Poke_Api_Demo

struct PokemonSearchFilterTests {
    private let index = [
        PokemonSummary(id: 4, name: "charmander"),
        PokemonSummary(id: 5, name: "charmeleon"),
        PokemonSummary(id: 25, name: "pikachu"),
        PokemonSummary(id: 122, name: "mr-mime"),
        PokemonSummary(id: 172, name: "pichu"),
        PokemonSummary(id: 669, name: "flabébé"),
        PokemonSummary(id: 10080, name: "pikachu-rock-star")
    ]

    private func ids(_ query: String, typeIDs: Set<Int>? = nil) -> [Int] {
        PokemonSearchFilter.filter(index, query: query, typeIDs: typeIDs).map(\.id)
    }

    @Test(arguments: [
        ("PIKA", [25, 10080]),
        ("  pika  ", [25, 10080]),
        ("FLABEBE", [669]),
        ("mr mime", [122]),
        ("Mr. Mime", []),
        ("zzz", [])
    ])
    func matchesNamesIgnoringCaseDiacriticsAndSpaces(query: String, expected: [Int]) {
        #expect(ids(query) == expected)
    }

    @Test(arguments: ["25", "#25", "#025"])
    func numericQueryMatchesExactID(query: String) {
        #expect(ids(query) == [25])
    }

    @Test func prefixMatchesComeBeforeContainsMatches() {
        let index = [
            PokemonSummary(id: 1, name: "bulbachu"),
            PokemonSummary(id: 2, name: "chu"),
            PokemonSummary(id: 3, name: "pichu"),
            PokemonSummary(id: 4, name: "chunky")
        ]

        let result = PokemonSearchFilter.filter(index, query: "chu", typeIDs: nil).map(\.id)

        #expect(result == [2, 4, 1, 3])
    }

    @Test func typeIDsRestrictMatches() {
        #expect(ids("char", typeIDs: [4]) == [4])
    }

    @Test func emptyQueryWithTypeReturnsTypeMembersInDexOrder() {
        #expect(ids("", typeIDs: [172, 25, 999]) == [25, 172])
    }

    @Test func emptyQueryWithoutTypeReturnsWholeIndex() {
        #expect(ids("") == index.map(\.id))
    }
}
