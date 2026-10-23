//
//  NetworkNameList.swift
//  ReCIT_iOS
//
//  Who a sheet of the Réseau graph names (PRD 0019, Q29, Q29 bis): up to four, every one of them;
//  past four, the first three and « et N autres » — never « et 1 autre », which takes as much
//  room as the name it would hide, so N is at least 2.
//
//  The friends a group's sheet names, the groups a friend's sheet names: the same rule, in the
//  order given.
//

import Foundation

nonisolated struct NetworkNameList: Hashable, Sendable {
    /// Up to this many, every name is said.
    static let namedInFull: Int = 4
    /// Past `namedInFull`, how many are named before « et N autres ».
    static let namedBeforeOthers: Int = 3

    /// The names said, in order.
    let names: [String]
    /// How many are left unnamed, counted in « et N autres »: 0, or 2 and more.
    let others: Int

    init(_ all: [String]) {
        if all.count <= Self.namedInFull {
            names = all
            others = 0
        } else {
            names = Array(all.prefix(Self.namedBeforeOthers))
            others = all.count - Self.namedBeforeOthers
        }
    }

    /// How many there are, named or not.
    var count: Int {
        names.count + others
    }

    var isEmpty: Bool {
        names.isEmpty
    }
}
