//
//  PokemonCardView.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 05/03/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct PokemonCard: View {
    let pokemon: PokemonEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(pokemon.name.capitalized)
                    .font(.title)
                    .foregroundStyle(pokemon.primaryType.color)

                HStack {
                    Image(systemName: pokemon.primaryType.icon)
                        .foregroundStyle(pokemon.primaryType.color)
                    Text(pokemon.primaryType.displayName)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 15)

            WebImage(url: pokemon.artworkURL)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 5)
        .accessibilityElement(children: .combine)
    }
}
