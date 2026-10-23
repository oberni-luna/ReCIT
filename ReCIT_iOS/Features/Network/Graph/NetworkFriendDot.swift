//
//  NetworkFriendDot.swift
//  ReCIT_iOS
//
//  A reader in the overview of the Réseau graph — `Graph / Friend · Dot` (`519:16390`, R3): a
//  24 pt disc with their photo, or plain `backgroundTinted` without one — no initials, which
//  would be smaller than any text style (Q37) — and no name. The ring is the full node's: a
//  hairline for a friend, dashed for a reader who asked to be one (Q5b bis), 2 pt of green when
//  lit (R2).
//
//  Its anchor is its centre. Touched through the graph's hit test, which grows it to 44 pt (Q36).
//  What VoiceOver says of it is the full node's (`NetworkGraphAccessibility`), set where it is
//  placed.
//

import SwiftUI

struct NetworkFriendDot: View {
    let reader: NetworkReaderNode
    var isHighlighted: Bool = false

    var body: some View {
        AvatarThumbnail(
            .reader(username: reader.reader.username),
            imageUrl: reader.reader.pictureURL,
            side: NetworkGraphMetrics.dotSide
        )
        .overlay {
            NetworkFriendRing(state: reader.state, isHighlighted: isHighlighted)
        }
    }
}

#Preview {
    HStack(spacing: .medium) {
        NetworkFriendDot(
            reader: .init(reader: .init(id: "1", username: "Camille"), state: .friend, isIsolated: false)
        )
        NetworkFriendDot(
            reader: .init(reader: .init(id: "2", username: "Inès"), state: .friend, isIsolated: false),
            isHighlighted: true
        )
        NetworkFriendDot(
            reader: .init(reader: .init(id: "3", username: "Ariane"), state: .requested, isIsolated: true)
        )
    }
    .padding()
}
