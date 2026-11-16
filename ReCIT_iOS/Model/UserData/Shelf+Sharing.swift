//
//  Shelf+Sharing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension Shelf {
    /// No one but its owner may open it: a link to it would open nothing for whoever receives it,
    /// so the étagère offers none. Any key at all — friends, groups, everyone, one group — lets
    /// someone else see it.
    var isVisibleToOwnerAlone: Bool {
        visibility.isEmpty
    }
}
