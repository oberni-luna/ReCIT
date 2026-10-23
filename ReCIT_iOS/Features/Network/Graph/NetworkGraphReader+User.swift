//
//  NetworkGraphReader+User.swift
//  ReCIT_iOS
//
//  A reader of the store, copied into the value the Réseau graph is built from.
//

import Foundation

extension NetworkGraphReader {
    init(user: User) {
        self.init(
            id: user._id,
            username: user.username,
            pictureURL: user.avatarURLValue,
            created: user.created
        )
    }
}
