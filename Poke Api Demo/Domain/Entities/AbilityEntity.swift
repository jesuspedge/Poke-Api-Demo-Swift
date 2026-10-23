//
//  AbilityEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct AbilityEntity: Identifiable, Hashable, Sendable {
    let name: String

    var id: String { name }
}
