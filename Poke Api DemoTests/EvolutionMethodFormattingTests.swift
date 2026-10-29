import Testing

@testable import Poke_Api_Demo

struct EvolutionMethodFormattingTests {
    @Test(arguments: [
        (EvolutionMethod.level(16), "Lv. 16"),
        (.item("thunder-stone"), "Thunder Stone"),
        (.trade(heldItem: nil), "Trade"),
        (.trade(heldItem: "metal-coat"), "Trade holding Metal Coat"),
        (.friendship, "Friendship"),
        (.other("shed"), "Shed"),
        (.other("level-up"), "Level Up"),
    ])
    func captions(method: EvolutionMethod, expected: String) {
        #expect(method.caption == expected)
    }
}
