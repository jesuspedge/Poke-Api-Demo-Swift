import SwiftUI

struct TypeFilterBar: View {
    @Binding var selection: PokemonType?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(PokemonType.allCases, id: \.self) { type in
                    TypeChip(type: type, isSelected: selection == type) {
                        // Tapping the selected chip clears the filter.
                        selection = selection == type ? nil : type
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .background(.bar)
    }
}

private struct TypeChip: View {
    let type: PokemonType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TypeBadge(type: type, isFilled: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("type-chip-\(type.rawValue)")
    }
}

#Preview {
    @Previewable @State var selection: PokemonType? = .fire
    TypeFilterBar(selection: $selection)
}
