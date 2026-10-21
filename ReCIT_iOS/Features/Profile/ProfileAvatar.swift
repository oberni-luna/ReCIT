//
//  ProfileAvatar.swift
//  ReCIT_iOS
//
//  My picture, round, as `ProfileToolbarItem` draws it: a glass circle with the profile icon,
//  covered by the picture once it has loaded.
//

import SwiftUI

struct ProfileAvatar: View {
    let url: URL

    var body: some View {
        ZStack {
            Image(systemName: "person")
                .foregroundStyle(.foregroundDefault)
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.clear
            }
        }
        .frame(
            width: ThumbnailSize.toolbar.sizeInPt,
            height: ThumbnailSize.toolbar.sizeInPt
        )
        .clipShape(.circle)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
