//
//  NetworkFriendRing.swift
//  ReCIT_iOS
//
//  The ring around a reader's avatar in the Réseau graph: a hairline for a friend, a dashed
//  `foregroundTinted` ring for a reader who asked to be one — the grammar of an invitation
//  (Q5b, Q32). Lit by a touch, the ring thickens to 2 pt of `foregroundTinted`, dashed still for a
//  requester (`Graph / Friend · Highlighted`, R2).
//

import SwiftUI

struct NetworkFriendRing: View {
    let state: NetworkReaderState
    var isHighlighted: Bool = false

    var body: some View {
        switch state {
        case .friend:
            if isHighlighted {
                Circle()
                    .strokeBorder(
                        DesignSystem.Color.foregroundTinted.color,
                        lineWidth: NetworkGraphMetrics.highlightedFriendRingWidth
                    )
            } else {
                Circle()
                    .strokeBorder(
                        DesignSystem.Color.borderDefault.color,
                        lineWidth: NetworkGraphMetrics.friendRingWidth
                    )
            }
        case .requested:
            Circle()
                .strokeBorder(
                    DesignSystem.Color.foregroundTinted.color,
                    style: .init(
                        lineWidth: isHighlighted
                            ? NetworkGraphMetrics.highlightedFriendRingWidth
                            : NetworkGraphMetrics.requesterRingWidth,
                        dash: NetworkGraphMetrics.dash
                    )
                )
        }
    }
}
