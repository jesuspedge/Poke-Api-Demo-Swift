//
//  PokemonDetailCard.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 23/03/26.
//

import Charts
import SDWebImageSwiftUI
import SwiftUI

struct PokemonDetailCard: View {
    let pokemon: PokemonEntity

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pokemon.name.capitalized)
                        .font(.title)
                        .bold()

                    HStack {
                        Image(systemName: pokemon.primaryType.icon)
                            .foregroundStyle(pokemon.primaryType.color)
                        Text(pokemon.primaryType.displayName)
                    }
                }
                .padding(.top, 20)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 15) { infoSections }
                    VStack(alignment: .leading, spacing: 15) { infoSections }
                }

                Chart(pokemon.stats) { stat in
                    BarMark(
                        x: .value("Stats", stat.name.capitalized),
                        y: .value("Value", stat.baseStat),
                        width: 20
                    )
                    .foregroundStyle(pokemon.primaryType.color)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisTick()
                        AxisGridLine().foregroundStyle(.clear)
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
                .accessibilityLabel("Base stats")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .shadow(radius: 5)
            .padding(.horizontal, 15)

            WebImage(url: pokemon.artworkURL)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, -60)
                .padding(.trailing, 20)
                .accessibilityHidden(true)
        }
        .padding(.top, 60)
        .padding(.bottom, 30)
    }

    // MARK: - Sections
    @ViewBuilder
    private var infoSections: some View {
        InfoSection(title: "Height", color: pokemon.primaryType.color) {
            Text(pokemon.formattedHeight())
        }

        InfoSection(title: "Weight", color: pokemon.primaryType.color) {
            Text(pokemon.formattedWeight())
        }

        InfoSection(title: "Category", color: pokemon.primaryType.color) {
            ForEach(pokemon.types, id: \.self) { type in
                Text(type.displayName)
            }
        }

        InfoSection(title: "Abilities", color: pokemon.primaryType.color) {
            ForEach(pokemon.abilities) { ability in
                Text(ability.name.capitalized)
            }
        }
    }
}

private struct InfoSection<Content: View>: View {
    let title: LocalizedStringKey
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .foregroundStyle(color)
            content
        }
        .accessibilityElement(children: .combine)
    }
}
