//
//  NetworkSheetAvatars.swift
//  ReCIT_iOS
//
//  The friends a group's sheet names, as a row of overlapping avatars (`amis en commun`,
//  `522:16837`): 32 pt each, 8 pt of each covered by the next, a white ring keeping them apart,
//  each drawn over the one before it, in the order the sentence names them. Initials where there
//  is no picture (Q21). Five at most (Q29) — `NetworkGroupSummary` has already cut the list.
//
//  Decorative to VoiceOver: the sentence above names them.
//

import SwiftUI

struct NetworkSheetAvatars: View {
    let readers: [NetworkGraphReader]

    private var ringedSide: CGFloat {
        NetworkGraphMetrics.sheetAvatarSide + 2 * NetworkGraphMetrics.sheetAvatarRingWidth
    }

    var body: some View {
        HStack(spacing: NetworkGraphMetrics.sheetAvatarStep - ringedSide) {
            ForEach(readers, id: \.id) { reader in
                AvatarThumbnail(
                    .reader(username: reader.username),
                    imageUrl: reader.pictureURL,
                    side: NetworkGraphMetrics.sheetAvatarSide
                )
                .padding(NetworkGraphMetrics.sheetAvatarRingWidth)
                .background(DesignSystem.Color.backgroundDefault.color, in: .circle)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NetworkSheetAvatars(
        readers: ["Inès", "Léa", "Rémi", "Camille", "Hugo"].map { .init(id: $0, username: $0) }
    )
    .padding()
}
