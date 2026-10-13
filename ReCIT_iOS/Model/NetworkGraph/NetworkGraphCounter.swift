//
//  NetworkGraphCounter.swift
//  ReCIT_iOS
//
//  « 42 amis · 6 groupes » — what I have, not what waits on me: accepted friends, and the groups
//  I administer or belong to. Requests and invitations are drawn, never counted (PRD 0019, Q10).
//

import Foundation

nonisolated struct NetworkGraphCounter: Hashable, Sendable {
    let friends: Int
    let groups: Int
}
