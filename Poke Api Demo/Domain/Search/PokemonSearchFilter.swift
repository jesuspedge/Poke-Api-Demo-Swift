import Foundation

enum PokemonSearchFilter {
    /// Filters the index by name or number, optionally restricted to `typeIDs`.
    /// Prefix matches come before substring matches; both keep the index order.
    static func filter(_ index: [PokemonSummary], query: String, typeIDs: Set<Int>?) -> [PokemonSummary] {
        let candidates = typeIDs.map { ids in index.filter { ids.contains($0.id) } } ?? index
        let term = normalize(query)

        guard !term.isEmpty else { return candidates }

        if let id = number(from: term) {
            return candidates.filter { $0.id == id }
        }

        var prefixMatches: [PokemonSummary] = []
        var containsMatches: [PokemonSummary] = []
        for pokemon in candidates {
            let name = normalize(pokemon.name)
            if name.hasPrefix(term) {
                prefixMatches.append(pokemon)
            } else if name.contains(term) {
                containsMatches.append(pokemon)
            }
        }
        return prefixMatches + containsMatches
    }

    // "Mr Mime" -> "mr-mime", "Flabébé" -> "flabebe"
    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: "-")
    }

    // "25", "#25" and "#025" all mean id 25
    private static func number(from term: String) -> Int? {
        let digits = term.hasPrefix("#") ? String(term.dropFirst()) : term
        guard !digits.isEmpty, digits.allSatisfy(\.isASCII), digits.allSatisfy(\.isNumber) else { return nil }
        return Int(digits)
    }
}
