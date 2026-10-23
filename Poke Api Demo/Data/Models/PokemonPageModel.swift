import Foundation

struct PokemonPageModel: Codable {
    let count: Int
    let next: String?
    let results: [NamedResourceModel]
}

struct NamedResourceModel: Codable {
    let name: String
    let url: String

    // PokéAPI resource URLs end with the id: ".../pokemon/25/"
    var id: Int? {
        URL(string: url).flatMap { Int($0.lastPathComponent) }
    }
}
