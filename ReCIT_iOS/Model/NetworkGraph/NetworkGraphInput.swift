//
//  NetworkGraphInput.swift
//  ReCIT_iOS
//
//  Everything the Réseau graph is drawn from, as values: me, my friends, the readers waiting on
//  my answer, and the groups I am an admin or a member of or invited into (PRD 0019).
//
//  The screen builds one from its `@Query` results (`NetworkGraphInput+Store`); the graph never
//  sees the store. What the graph does not draw is not here at all: a friend request I sent, a
//  request to join I sent, a declined invitation (Q4, Q5).
//

import Foundation

nonisolated struct NetworkGraphInput: Hashable, Sendable {
    let me: NetworkGraphReader
    /// Accepted friends, in any order.
    let friends: [NetworkGraphReader]
    /// Readers who asked to be my friend and wait on my answer, in any order.
    let requesters: [NetworkGraphReader]
    /// My groups and the invitations I received, in any order.
    let groups: [NetworkGraphGroup]
}
