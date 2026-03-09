//
//  Poke_Api_DemoApp.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 12/08/24.
//

import SwiftUI

@main
struct Poke_Api_DemoApp: App {
    @State private var viewModel = AppFactory.makeListViewModel()

    var body: some Scene {
        WindowGroup {
            PokemonListView(viewModel: viewModel)
        }
    }
}
