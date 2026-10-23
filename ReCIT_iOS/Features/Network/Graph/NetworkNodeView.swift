//
//  NetworkNodeView.swift
//  ReCIT_iOS
//
//  One node of the Réseau graph as drawn at the current level: « Vous »; a group's card, or its
//  compact tile in the overview; a reader's avatar and handle, or their dot in the overview (Q31,
//  R3). The constellation lays the nodes out in VoiceOver's reading order (Q44) and draws them
//  in its own by `zIndex`, so one view stands for every kind of node.
//

import SwiftUI

struct NetworkNodeView: View {
    /// What the node stands for.
    enum Subject {
        case me(NetworkGraphReader)
        case group(NetworkGraphGroup)
        case reader(NetworkReaderNode)
    }

    let subject: Subject
    /// Drawn as in the overview.
    var isOverview: Bool = false
    /// The node touched — a group takes the selected look.
    var isSelected: Bool = false
    /// Lit by the node touched — a reader takes the highlighted look.
    var isHighlighted: Bool = false

    var body: some View {
        switch subject {
        case .me(let me):
            NetworkMeNode(username: me.username, imageUrl: me.pictureURL)
        case .group(let group):
            if isOverview {
                NetworkGroupTile(group: group, isSelected: isSelected)
            } else {
                NetworkGroupCard(group: group, isSelected: isSelected)
            }
        case .reader(let reader):
            if isOverview {
                NetworkFriendDot(reader: reader, isHighlighted: isHighlighted)
            } else {
                NetworkFriendNode(reader: reader, isHighlighted: isHighlighted)
            }
        }
    }
}
