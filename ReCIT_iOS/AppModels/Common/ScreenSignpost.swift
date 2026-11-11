//
//  ScreenSignpost.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

import OSLog

/// Marks, in an Instruments trace, the screen that comes on display, so that a hitch can be put
/// down to a screen (`docs/wiki/performance.md`). One event per appearance, under `asso.recits` /
/// `screen`; the message is the screen's name, never a reader's.
enum ScreenSignpost: String {
    case networkFriends
    case networkGroups
    case lists

    private static let signposter: OSSignposter = .init(subsystem: "asso.recits", category: "screen")

    init(_ segment: NetworkSegment) {
        switch segment {
        case .friends:
            self = .networkFriends
        case .groups:
            self = .networkGroups
        }
    }

    func emit() {
        Self.signposter.emitEvent("Screen", "\(rawValue, privacy: .public)")
    }
}
