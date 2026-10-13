//
//  NetworkFriendRing.swift
//  ReCIT_iOS
//
//  The ring around a reader's avatar in the Réseau graph: a hairline for a friend, a dashed
//  `foregroundTinted` ring for a reader who asked to be one — the grammar of an invitation
//  (Q5b, Q32).
//

import SwiftUI

struct NetworkFriendRing: View {
    let state: NetworkReaderState

    var body: some View {
        switch state {
        case .friend:
            Circle()
                .strokeBorder(
                    DesignSystem.Color.borderDefault.color,
                    lineWidth: NetworkGraphMetrics.friendRingWidth
                )
        case .requested:
            Circle()
                .strokeBorder(
                    DesignSystem.Color.foregroundTinted.color,
                    style: .init(
                        lineWidth: NetworkGraphMetrics.requesterRingWidth,
                        dash: NetworkGraphMetrics.dash
                    )
                )
        }
    }
}
