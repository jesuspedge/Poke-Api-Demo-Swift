import Testing

@testable import Poke_Api_Demo

struct TypeColorTests {
    @Test func everyTypeHasItsOwnColor() {
        let palettes = PokemonType.allCases.map(\.palette)

        #expect(Set(palettes.map(\.light)).count == PokemonType.allCases.count)
        #expect(Set(palettes.map(\.dark)).count == PokemonType.allCases.count)
    }

    // The colors are used for text and icons on the system background.
    @Test(arguments: PokemonType.allCases)
    func colorIsReadableOnTheBackground(type: PokemonType) {
        #expect(ColorContrast.ratio(type.palette.light, ColorContrast.white) >= 3)
        #expect(ColorContrast.ratio(type.palette.dark, ColorContrast.black) >= 4)
    }

    @Test(arguments: PokemonType.allCases)
    func filledBadgeTextIsReadable(type: PokemonType) {
        let palette = type.palette
        let text = palette.textOnFill

        #expect(ColorContrast.ratio(text.light, palette.light) >= ColorContrast.minimum)
        #expect(ColorContrast.ratio(text.dark, palette.dark) >= ColorContrast.minimum)
    }

    @Test func badgeTextIsWhiteUnlessTheFillIsTooLight() {
        #expect(ColorContrast.textColor(onFill: 0xC22E28) == ColorContrast.white)
        #expect(ColorContrast.textColor(onFill: 0xF7D02C) == ColorContrast.black)
    }

    @Test func contrastMatchesTheWCAGExtremes() {
        #expect(ColorContrast.ratio(ColorContrast.white, ColorContrast.black) == 21)
        #expect(ColorContrast.ratio(0x777777, 0x777777) == 1)
    }
}
