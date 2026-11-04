//
//  ListRowMetaLine.swift
//  ReCIT_iOS
//
//  The line above a list's name: how many works or authors it holds, and for a friend's list,
//  before that, their picture and their name — « Léa • 14 œuvres ». Above the name rather than
//  after the count, it reads as whose the list is before what it is called.
//

import SwiftUI

struct ListRowMetaLine: View {
    let owner: User?
    let count: LocalizedStringResource

    /// The picture sits on the line, at the size of its text.
    @ScaledMetric(relativeTo: .caption) private var avatarSide: CGFloat = 16

    var body: some View {
        HStack(spacing: .xSmall) {
            if let owner {
                HStack(spacing: .xxSmall) {
                    AvatarThumbnail(
                        .reader(username: owner.username),
                        imageUrl: owner.avatarURLValue,
                        side: avatarSide
                    )

                    Text(owner.username)
                        .lineLimit(1)
                }

                Text(verbatim: "•")
                    .accessibilityHidden(true)
            }

            Text(count)
                .lineLimit(1)
        }
        .textStyle(.caption200)
        .foregroundStyle(.foregroundSecondary)
    }
}
