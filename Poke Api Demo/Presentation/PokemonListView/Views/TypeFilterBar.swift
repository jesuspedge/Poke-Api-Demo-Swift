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
            Label(type.displayName, systemImage: type.icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : type.color)
                .background(type.color.opacity(isSelected ? 1 : 0.15), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: PokemonType? = .fire
    TypeFilterBar(selection: $selection)
}
