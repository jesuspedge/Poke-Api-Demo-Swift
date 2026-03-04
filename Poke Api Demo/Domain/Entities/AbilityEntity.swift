//
//  AbilityEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

import Foundation

class AbilityEntity: Identifiable {
    let id: UUID
    let name: String

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
