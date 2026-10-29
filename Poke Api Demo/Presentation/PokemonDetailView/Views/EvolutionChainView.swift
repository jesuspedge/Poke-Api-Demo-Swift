import SDWebImageSwiftUI
import SwiftUI

struct EvolutionChainView: View {
    let state: EvolutionState
    let selectedID: Int?
    // The Pokémon this detail screen shows; selecting it again offers no "View" button.
    let currentID: Int
    let type: PokemonType
    let onSelect: (Int) -> Void
    let onRetry: () async -> Void

    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution")
                .font(.title3)
                .bold()
                .foregroundStyle(type.color)

            switch state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)

            case .loaded(let chain) where !chain.doesEvolve:
                Text("Does not evolve.")
                    .foregroundStyle(.secondary)

            case .loaded(let chain):
                stages(chain)
                viewButton(chain)

            case .failed(let message):
                HStack {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") {
                        Task { await onRetry() }
                    }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 15)
        .padding(.bottom, 30)
    }

    private func stages(_ chain: EvolutionChain) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(Array(chain.stages.enumerated()), id: \.offset) { index, stage in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }

                    VStack(spacing: 8) {
                        ForEach(stage, id: \.species.id) { node in
                            member(node)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func member(_ node: EvolutionNode) -> some View {
        let isSelected = node.species.id == selectedID

        return Button {
            withAnimation(.spring(duration: 0.35)) {
                onSelect(node.species.id)
            }
        } label: {
            VStack(spacing: 2) {
                WebImage(url: node.artworkURL)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)

                Text(node.species.name.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                if let method = node.method {
                    Text(method.caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96)
            .padding(.vertical, 6)
            .background {
                // The highlight slides from the old selection to the new one.
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(type.color.opacity(0.18))
                        .matchedGeometryEffect(id: "selection", in: selection)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("evolution-member-\(node.species.id)")
    }

    @ViewBuilder
    private func viewButton(_ chain: EvolutionChain) -> some View {
        if let selectedID, selectedID != currentID,
            let node = chain.stages.joined().first(where: { $0.species.id == selectedID })
        {
            NavigationLink(value: EvolutionLink(id: selectedID)) {
                Label("View \(node.species.name.capitalized)", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(type.colorOnFill)
            }
            .buttonStyle(.borderedProminent)
            .tint(type.color)
            .accessibilityIdentifier("evolution-view-button")
        }
    }
}

#Preview {
    @Previewable @State var selectedID: Int? = 1
    let chain = EvolutionChain(
        id: 1,
        root: EvolutionNode(
            species: PokemonSummary(id: 133, name: "eevee"),
            artworkURL: EvolutionMapper.artworkURL(forSpeciesID: 133),
            method: nil,
            evolvesTo: [
                EvolutionNode(
                    species: PokemonSummary(id: 134, name: "vaporeon"),
                    artworkURL: EvolutionMapper.artworkURL(forSpeciesID: 134),
                    method: .item("water-stone"), evolvesTo: []),
                EvolutionNode(
                    species: PokemonSummary(id: 196, name: "espeon"),
                    artworkURL: EvolutionMapper.artworkURL(forSpeciesID: 196),
                    method: .friendship, evolvesTo: []),
            ]
        )
    )
    NavigationStack {
        EvolutionChainView(
            state: .loaded(chain),
            selectedID: selectedID,
            currentID: 133,
            type: .normal,
            onSelect: { selectedID = $0 },
            onRetry: {}
        )
    }
}
