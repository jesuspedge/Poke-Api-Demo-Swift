//
//  ContentView.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct PokemonListView: View {
    @State var loading: Bool = true
    @State var hasError: Bool = false
    @State var errorString: String = ""
    @State var pokemons: [PokemonEntity] = []

    var body: some View {

        if loading {
            ProgressView()
                .onAppear {
                    Task {
                        do {
                            pokemons = try await PokemonRemoteSource().getPokemons()
                        } catch {
                            print("Error \(error)")
                            hasError = true
                            errorString = "Error: \(error)"
                        }
                        loading = false
                    }
                }
        } else if hasError {
            VStack {
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .frame(maxWidth: 50, maxHeight: 50)
                    .padding(.bottom, 30)

                Text("Something goes wrong")
                    .font(.title2)
                    .padding(.bottom, 10)

                Text(errorString)
            }
            .padding(.horizontal, 30)
        }
        else {
            NavigationStack {
                List(pokemons) { pokemon in
                    ZStack {
                        PokemonCard(pokemon: pokemon)

                        NavigationLink(destination: PokemonDetail(pokemon: pokemon)) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .navigationTitle("CHOOSE YOUR POKEMON")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}



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

#Preview {
    PokemonListView()
}
