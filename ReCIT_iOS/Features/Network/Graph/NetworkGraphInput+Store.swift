//
//  NetworkGraphInput+Store.swift
//  ReCIT_iOS
//
//  The Réseau graph's snapshot, taken from what « Tout » reads through `@Query` (ADR 0001): the
//  readers of the store and where I stand with each, and my groups as `GroupModel` sorts them.
//
//  Only what the graph draws gets in (PRD 0019, Q4, Q5): my friends and the readers waiting on my
//  answer — never a request I sent, nor a reader met elsewhere — and the groups I administer,
//  belong to or am invited into — never a request to join I sent, which stays in the Groupes
//  list.
//

import Foundation

extension NetworkGraphInput {
    /// - Parameters:
    ///   - me: The signed-in reader as the store holds them, or `nil` before their row arrives.
    ///   - myUserId: Who is signed in, for when `me` is not in the store yet.
    ///   - users: Every reader in the store.
    ///   - groups: My groups by where I stand in each.
    init(
        me: User?,
        myUserId: String?,
        users: [User],
        groups: MyGroups
    ) {
        let myId: String = me?._id ?? myUserId ?? ""
        var usernames: [String: String] = [:]
        for user in users {
            usernames[user._id] = user.username
        }
        let others: [User] = users.filter { $0._id != myId }

        self.init(
            me: .init(
                id: myId,
                username: me?.username ?? usernames[myId] ?? "",
                pictureURL: me?.avatarURLValue,
                created: me?.created
            ),
            friends: others.filter { $0.relation == .friend }.map(NetworkGraphReader.init(user:)),
            requesters: others.filter { $0.relation == .requestReceived }.map(NetworkGraphReader.init(user:)),
            groups: (groups.mine + groups.invitations).compactMap {
                NetworkGraphGroup(
                    group: $0,
                    me: myId,
                    usernames: usernames
                )
            }
        )
    }
}
