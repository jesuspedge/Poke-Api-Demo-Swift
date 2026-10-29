import Foundation
import Testing

@testable import Poke_Api_Demo

struct FormattingTests {
    private let pokemon = PokemonEntity.fixture()
    private let us = Locale(identifier: "en_US")
    private let metric = Locale(identifier: "en_DE")

    @Test func heightUsesImperialUnitsInUSLocale() {
        #expect(pokemon.formattedHeight(locale: us) == "28 in")
    }

    @Test func heightUsesMetricUnitsInMetricLocale() {
        #expect(pokemon.formattedHeight(locale: metric) == "70 cm")
    }

    @Test func weightUsesPoundsInUSLocale() {
        #expect(pokemon.formattedWeight(locale: us) == "15 lb")
    }

    @Test func weightUsesKilogramsInMetricLocale() {
        #expect(pokemon.formattedWeight(locale: metric) == "6,9 kg")
    }
}
