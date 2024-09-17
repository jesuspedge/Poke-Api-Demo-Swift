//
//  ApiNetwork.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import Foundation

class ApiNetwork {
    private let baseUrl: String = "https://pokeapi.co/api/v2/pokemon/"
    
    func getPokemons() async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        
        for number in 1...20 {
            let url = URL(string: "\(baseUrl)\(String(number))")!
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
            
            pokemons.append(pokemon)
        }
        
        return pokemons
    }
    
    func getfirstPokemon() async throws -> Pokemon {
        
        let url = URL(string: "\(baseUrl)1")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
        
        return pokemon
    }
}
