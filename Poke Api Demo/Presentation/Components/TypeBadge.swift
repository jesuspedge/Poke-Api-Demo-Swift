import SwiftUI

// A capsule with a type's icon and name; filled when selected or highlighted.
struct TypeBadge: View {
    let type: PokemonType
    var isFilled = false

    var body: some View {
        Label(type.displayName, systemImage: type.icon)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isFilled ? Color.white : type.color)
            .background(type.color.opacity(isFilled ? 1 : 0.15), in: .capsule)
    }
}

#Preview {
    HStack {
        TypeBadge(type: .fire)
        TypeBadge(type: .water, isFilled: true)
    }
}
