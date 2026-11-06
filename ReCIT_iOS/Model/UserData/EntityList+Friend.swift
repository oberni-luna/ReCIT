//
//  EntityList+Friend.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation

extension EntityList {
    /// The friend who made this list: `nil` for one of mine, and for a stranger's, whose lists
    /// the store holds once their profile has been opened.
    ///
    /// - Parameters:
    ///   - myUserId: The signed-in reader's id.
    ///   - friendsById: My friends, by id.
    /// - Returns: The friend, or `nil` when the list is not a friend's.
    func friendCreator(
        myUserId: String?,
        friendsById: [String: User]
    ) -> User? {
        guard let creatorId, creatorId != myUserId else { return nil }
        return friendsById[creatorId]
    }
}
