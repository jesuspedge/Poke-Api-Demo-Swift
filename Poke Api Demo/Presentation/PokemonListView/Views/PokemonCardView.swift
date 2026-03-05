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

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack {
                Text(pokemon.name.capitalized)
                    .font(.title)
                    .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                    .frame(maxWidth: .infinity, maxHeight: 25, alignment: .leading)


                HStack {
                    Image(systemName: pokemonTypeIconDic[pokemon.types.first!.name] ?? "star.fill")
                        .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                    Text(pokemon.types.first!.name.capitalized)
                }
                .frame(maxWidth: .infinity, maxHeight: 25, alignment: .leading)
            }
            .padding(.leading, 15)

            WebImage(url: URL(string: pokemon.sprites.officialArtworkURL))
                .resizable()
                .frame(width: 170, height: 170)
                .padding(.top, 30)
                .padding(.leading, -10)

        }
        .frame(maxWidth: .infinity,  maxHeight: 150)
        .background(colorScheme == .light ? Color.white : Color.gray.opacity(0.3))
        .cornerRadius(10)
        .shadow(radius: 5)

    }
}
