//
//  Shelf+Sharing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension Shelf {
    /// Whether the étagère offers « Partager ». One of mine without a visibility key is mine
    /// alone: a link to it would open nothing for whoever receives it. Any key at all — friends,
    /// groups, everyone, one group — lets someone else see it. A friend's always offers it: I see
    /// it, and inventaire.io may send its keys to its owner alone.
    func isShareable(isMine: Bool) -> Bool {
        isMine == false || visibility.isEmpty == false
    }
}
