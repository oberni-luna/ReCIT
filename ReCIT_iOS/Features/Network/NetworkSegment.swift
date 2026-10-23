//
//  NetworkSegment.swift
//  ReCIT_iOS
//
//  The parts of the Réseau tab: the whole network drawn around me, the readers I am close to one
//  by one, and the groups I share books with. See PRD 0016 and PRD 0019.
//
//  **« Tout » is compiled in `DEBUG` only** (PRD 0019, Q47) until the device review of the graph:
//  the intermediate slices must not reach a Release build. It is declared first, so it is the
//  first segment of the control wherever it exists.
//

import SwiftUI

enum NetworkSegment: String, CaseIterable, Hashable {
    #if DEBUG
    /// The constellation: « Vous » at the centre, my groups and my friends around me.
    case all
    #endif
    case friends
    case groups

    /// The `UserDefaults` key the last segment chosen is kept under, so the tab reopens on it.
    static let storageKey: String = "network.lastSegment"

    /// Where the tab opens the very first time: on « Tout » wherever it exists (Q12), on Amis
    /// otherwise.
    static var firstLaunch: NetworkSegment {
        #if DEBUG
        .all
        #else
        .friends
        #endif
    }

    /// The segment a stored value reopens on.
    ///
    /// Nothing stored yet is the first launch. A value this build does not know — « all » kept by
    /// a `DEBUG` build and read by a Release one, or a segment since removed — falls back on Amis
    /// (Q12), the list the tab opened on before « Tout » existed.
    static func restored(from rawValue: String?) -> NetworkSegment {
        guard let rawValue else { return firstLaunch }

        return .init(rawValue: rawValue) ?? .friends
    }

    var title: LocalizedStringKey {
        switch self {
        #if DEBUG
        case .all:
            "network.segment.all"
        #endif
        case .friends:
            "network.segment.friends"
        case .groups:
            "network.segment.groups"
        }
    }

    /// The ground the segment is drawn on, under the control as well: white for the graph, nav
    /// bar included, the lists' grouped ground under their cells (Q14; black in dark, feature 0039).
    var ground: DesignSystem.Color {
        switch self {
        #if DEBUG
        case .all:
            .backgroundDefault
        #endif
        case .friends, .groups:
            .backgroundGrouped
        }
    }
}
