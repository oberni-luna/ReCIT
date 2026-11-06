//
//  User+ById.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation

extension User {
    /// Readers keyed by their id, the first one kept when the store holds a reader twice.
    ///
    /// - Parameter users: The readers to key.
    /// - Returns: Each reader under its `_id`.
    static func byId(_ users: [User]) -> [String: User] {
        .init(users.map { ($0._id, $0) }) { first, _ in first }
    }
}
