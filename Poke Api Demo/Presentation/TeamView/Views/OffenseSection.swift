import SwiftUI

// The single types the team's own types hit for 2×, and the ones none of them do.
struct OffenseSection: View {
    let analysis: TeamAnalysis

    private let columns = [GridItem(.adaptive(minimum: 104), alignment: .leading)]

    var body: some View {
        Section {
            badges(analysis.covered, isFilled: true, emptyText: "None yet")
        } header: {
            Text("Super effective against (\(analysis.covered.count)/\(PokemonType.allCases.count))")
        }

        if !analysis.uncovered.isEmpty {
            Section("No super-effective coverage") {
                badges(analysis.uncovered, isFilled: false, emptyText: "")
            }
        }
    }

    @ViewBuilder
    private func badges(_ types: [PokemonType], isFilled: Bool, emptyText: String) -> some View {
        if types.isEmpty {
            Text(emptyText).foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TypeBadge(type: type, isFilled: isFilled)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
