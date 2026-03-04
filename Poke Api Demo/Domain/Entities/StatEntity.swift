//
//  StatEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

import Foundation

class StatEntity: Identifiable {
    let id: UUID
    let baseStat: Int
    let name: String

    init(id: UUID, baseStat: Int, name: String) {
        self.id = id
        self.baseStat = baseStat
        self.name = name
    }
}
