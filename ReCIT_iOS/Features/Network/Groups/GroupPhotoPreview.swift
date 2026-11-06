//
//  GroupPhotoPreview.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// The group's photo at the head of « Réglages du groupe », in the shape it has everywhere else:
/// the bytes just picked, the photo on the server, or the group glyph.
struct GroupPhotoPreview: View {
    static let side: CGFloat = 104

    let picture: GroupPictureEdit
    /// The photo on the server, shown while the edit has not touched it.
    let savedPictureURL: String?

    var body: some View {
        AvatarThumbnail(
            .group,
            imageUrl: picture == .unchanged ? savedPictureURL : nil,
            side: Self.side
        )
        .overlay {
            if let data = picture.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.side, height: Self.side)
                    .clipShape(RoundedRectangle(cornerRadius: .medium))
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview("No photo") {
    GroupPhotoPreview(picture: .unchanged, savedPictureURL: nil)
}

#Preview("Removed") {
    GroupPhotoPreview(picture: .removed, savedPictureURL: "https://inventaire.io/img/groups/abc")
}
