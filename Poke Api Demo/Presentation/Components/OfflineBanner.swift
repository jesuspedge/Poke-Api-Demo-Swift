import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Label("You're offline. Showing saved Pokémon.", systemImage: "wifi.slash")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.bar)
    }
}

#Preview {
    OfflineBanner()
}
