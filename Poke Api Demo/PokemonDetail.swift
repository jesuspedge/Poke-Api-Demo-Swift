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
    let pokemon: Pokemon
    
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
                    Image(systemName: pokemonTypeIconDic[pokemon.types.first!.type.name] ?? "star.fill")
                        .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
                    Text(pokemon.types.first!.type.name.capitalized)
                }
                .frame(maxWidth: .infinity, maxHeight: 25, alignment: .leading)
                .padding(.leading, 10)
                .padding(.bottom, 20)
                
                
                HStack(alignment: .top, spacing: 15) {
                    VStack {
                        Text("Height")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
                        Text("\(String(pokemon.height)) in.")
                    }
                    
                    VStack {
                        Text("Weight")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
                        Text("\(String(pokemon.weight)) lbs.")
                    }
                    
                    VStack {
                        Text("Category")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
                        
                        ForEach(pokemon.types) { element in
                            Text(element.type.name.capitalized)
                        }
                    }
                    
                    VStack {
                        Text("Abilities")
                            .bold()
                            .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
                        
                        ForEach(pokemon.abilities) { element in
                            Text(element.ability.name.capitalized)
                        }
                    }
                }
                .padding(.horizontal, 10)
                
                Chart {
                    ForEach(pokemon.stats) { element in
                        BarMark(
                            x: .value("Stats", element.stat.name.capitalized),
                            y: .value("Value", element.baseStat),
                            width: 20
                        )
                        .foregroundStyle(pokemonTypeColorDic[pokemon.types.first!.type.name] ?? .black)
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
            
            WebImage(url: URL(string: pokemon.sprites.other.officialArtwork.frontDefault))
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
   
    PokemonDetail(pokemon: Pokemon(
        id: 1,
        name: "bulbasaur",
        abilities: [
            Ability(ability: AbilityClass(name: "overgrow")),
            Ability(ability: AbilityClass(name: "chlorophyll")),
        ],
        height: 7,
        sprites:
            Sprites(
                other: Other(
                    officialArtwork: OfficialArtwork(
                        frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png"))),
        stats: [
            Stat(baseStat: 45, stat: StatClass(name: "hp")),
            Stat(baseStat: 49, stat: StatClass(name: "attack")),
            Stat(baseStat: 49, stat: StatClass(name: "defense")),
            Stat(baseStat: 65, stat: StatClass(name: "special-attack")),
            Stat(baseStat: 65, stat: StatClass(name: "special-defense")),
            Stat(baseStat: 45, stat: StatClass(name: "speed")),
        ],
        types: [
        Types(
            type: TypeClass(
                name: "grass")),
        Types(
            type: TypeClass(
                name: "poison"))
        ],
        weight: 69)
    )

}
