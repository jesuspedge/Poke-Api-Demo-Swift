//
//  PokemonDetail.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 15/08/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Charts

struct PokemonDetail: View {
    let pokemon: PokemonEntity

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Text(pokemon.name.capitalized)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, maxHeight: 25, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 20)

                HStack {
                    Image(systemName: pokemonTypeIconDic[pokemon.types.first!.name] ?? "star.fill")
                        .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                    Text(pokemon.types.first!.name.capitalized)
                }
                .frame(maxWidth: .infinity, maxHeight: 25, alignment: .leading)
                .padding(.leading, 10)
                .padding(.bottom, 20)


                HStack(alignment: .top, spacing: 15) {
                    VStack {
                        Text("Height")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                        Text("\(String(pokemon.height)) in.")
                    }

                    VStack {
                        Text("Weight")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                        Text("\(String(pokemon.weight)) lbs.")
                    }

                    VStack {
                        Text("Category")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)

                        ForEach(pokemon.types) { element in
                            Text(element.name.capitalized)
                        }
                    }

                    VStack {
                        Text("Abilities")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)

                        ForEach(pokemon.abilities) { element in
                            Text(element.name.capitalized)
                        }
                    }
                }
                .padding(.horizontal, 10)

                Chart {
                    ForEach(pokemon.stats) { element in
                        BarMark(
                            x: .value("Stats", element.name.capitalized),
                            y: .value("Value", element.baseStat),
                            width: 20
                        )
                        .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.name] ?? .black)
                    }
                }
                .chartXAxis() {
                    AxisMarks(position: .bottom) {_ in
                        AxisTick()
                        AxisGridLine().foregroundStyle(.clear)
                        AxisValueLabel()
                    }
                }
                .chartYAxis() {
                    AxisMarks(position: .leading) {_ in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisValueLabel()
                    }
                }
                .frame(maxHeight: 150)
                .padding(.vertical, 15)
                .padding(.horizontal, 10)


            }
            .background(colorScheme == .light ? Color.white : Color.gray.opacity(0.3))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal, 15)

            WebImage(url: URL(string: pokemon.sprites.officialArtworkURL))
                .resizable()
                .frame(width: 150, height: 150)
                .padding(.top, -60)
                .padding(.trailing, 20)

        }
        .padding(.top, 60)
        .padding(.bottom, 30)
    }
}

#Preview {
    PokemonDetail(pokemon: PokemonEntity(
        id: 1,
        name: "bulbasaur",
        abilities: [
            AbilityEntity(id: UUID(), name: "overgrow"),
            AbilityEntity(id: UUID(), name: "chlorophyll"),
        ],
        height: 7,
        sprites: SpritesEntity(officialArtworkURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"),
        stats: [
            StatEntity(id: UUID(), baseStat: 45, name: "hp"),
            StatEntity(id: UUID(), baseStat: 49, name: "attack"),
            StatEntity(id: UUID(), baseStat: 49, name: "defense"),
            StatEntity(id: UUID(), baseStat: 65, name: "special-attack"),
            StatEntity(id: UUID(), baseStat: 65, name: "special-defense"),
            StatEntity(id: UUID(), baseStat: 45, name: "speed"),
        ],
        types: [
            TypesEntity(id: UUID(), name: "grass"),
            TypesEntity(id: UUID(), name: "poison")
        ],
        weight: 69)
    )
}
