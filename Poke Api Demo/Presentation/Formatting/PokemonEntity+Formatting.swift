import Foundation

extension PokemonEntity {
    func formattedHeight(locale: Locale = .autoupdatingCurrent) -> String {
        Measurement(value: heightInMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .personHeight).locale(locale))
    }

    func formattedWeight(locale: Locale = .autoupdatingCurrent) -> String {
        Measurement(value: weightInKg, unit: UnitMass.kilograms)
            .formatted(.measurement(width: .abbreviated, usage: .personWeight).locale(locale))
    }
}
