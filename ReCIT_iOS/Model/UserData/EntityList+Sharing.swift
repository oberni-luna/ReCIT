//
//  EntityList+Sharing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension EntityList {
    /// Whether the list, and each of its elements, offers « Partager ». One of mine without a
    /// visibility key is mine alone: a link to it would open nothing for whoever receives it. A
    /// friend's always offers it: I see it, and a list seen through one group arrives without
    /// its `group:` key.
    func isShareable(isMine: Bool) -> Bool {
        isMine == false || visibility.isEmpty == false
    }
}
