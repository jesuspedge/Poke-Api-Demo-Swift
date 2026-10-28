import Foundation

extension EvolutionMethod {
    // "Lv. 16", "Thunder Stone", "Trade holding Metal Coat"
    var caption: String {
        switch self {
        case .level(let level):
            String(localized: "Lv. \(level)")
        case .item(let item):
            Self.displayName(item)
        case .trade(let heldItem?):
            String(localized: "Trade holding \(Self.displayName(heldItem))")
        case .trade(nil):
            String(localized: "Trade")
        case .friendship:
            String(localized: "Friendship")
        case .other(let trigger):
            Self.displayName(trigger)
        }
    }

    // API names are kebab-case: "thunder-stone" -> "Thunder Stone"
    private static func displayName(_ apiName: String) -> String {
        apiName.split(separator: "-").map(\.capitalized).joined(separator: " ")
    }
}
