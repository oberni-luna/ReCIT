//
//  NetworkMeNode.swift
//  ReCIT_iOS
//
//  « Vous », at the centre of the Réseau graph — `Graph / Me` (`512:16006`) in Figma: my avatar at
//  72 pt in a `backgroundTintedInverse` ring, and a « Vous » pill climbing over its bottom edge.
//  Without a picture, my initials on the tinted disc, like every other reader (Q20, Q21).
//
//  Nothing happens when it is touched (Q28), so it is not a button; VoiceOver reads it as the
//  heading the rest of the network hangs from (Q44).
//

import SwiftUI

struct NetworkMeNode: View {
    /// My inventaire.io handle, for the initials drawn without a picture.
    let username: String
    /// My picture, already absolute; `nil` when I have none.
    let imageUrl: String?

    var body: some View {
        VStack(spacing: -NetworkGraphMetrics.meLabelOverlap) {
            AvatarThumbnail(
                .reader(username: username),
                imageUrl: imageUrl,
                side: NetworkGraphMetrics.meSide
            )
            .overlay {
                Circle()
                    .strokeBorder(
                        DesignSystem.Color.backgroundTintedInverse.color,
                        lineWidth: NetworkGraphMetrics.meRingWidth
                    )
            }

            Text("network.graph.me")
                .textStyle(.action200)
                .foregroundStyle(.foregroundInverse)
                .lineLimit(1)
                .padding(NetworkGraphMetrics.meLabelInsets)
                .background(DesignSystem.Color.backgroundTintedInverse.color, in: .capsule)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("network.graph.me"))
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    HStack(spacing: .large) {
        NetworkMeNode(username: "olivier_berni", imageUrl: nil)
        NetworkMeNode(username: "Léa", imageUrl: "https://inventaire.io/img/broken")
    }
    .padding()
}
