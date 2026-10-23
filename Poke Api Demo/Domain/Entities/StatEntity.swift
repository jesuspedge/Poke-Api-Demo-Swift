//
//  StatEntity.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 03/03/26.
//

struct StatEntity: Identifiable, Hashable, Sendable {
    let name: String
    let baseStat: Int

    var id: String { name }
}
