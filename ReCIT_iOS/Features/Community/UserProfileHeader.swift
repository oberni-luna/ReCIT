//
//  UserProfileHeader.swift
//  ReCIT_iOS
//
//  The head of a reader's profile, centred: their picture, their name, how many books they
//  hold, and their bio. It stands in for the navigation title, which the screen no longer
//  shows — the name is already in front of the reader. See PRD 0031.
//

import SwiftUI

struct UserProfileHeader: View {
    let user: User

    var body: some View {
        VStack(spacing: .small) {
            avatar

            VStack(spacing: .xxSmall) {
                Text(user.username)
                    .textStyle(.title50)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityAddTraits(.isHeader)

                UserItemCountText(user: user)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
            }

            if let bio = user.bio, bio.isEmpty == false {
                Text(bio)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .medium)
    }

    /// The picture, or the person glyph on the empty grey disc when there is none: the head of
    /// the screen keeps its shape either way.
    @ViewBuilder
    private var avatar: some View {
        if let image = user.avatarURLValue {
            CellThumbnail(imageUrl: image, cornerRadius: .full, size: .xlarge)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "person")
                .textStyle(.title200)
                .foregroundStyle(.foregroundSecondary)
                .frame(width: ThumbnailSize.xlarge.sizeInPt, height: ThumbnailSize.xlarge.sizeInPt)
                .background(DesignSystem.Color.backgroundDisable.color, in: .circle)
                .accessibilityHidden(true)
        }
    }
}
