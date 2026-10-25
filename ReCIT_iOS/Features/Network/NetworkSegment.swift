//
//  NetworkSegment.swift
//  ReCIT_iOS
//
//  The two halves of the Réseau tab: the readers I am close to one by one, and the groups I
//  share books with. See PRD 0016 and the `Réseau · Onglet & Groupes` Figma pass.
//

import SwiftUI

enum NetworkSegment: String, CaseIterable, Hashable {
    case friends
    case groups

    var title: LocalizedStringKey {
        switch self {
        case .friends:
            "network.segment.friends"
        case .groups:
            "network.segment.groups"
        }
    }
}
