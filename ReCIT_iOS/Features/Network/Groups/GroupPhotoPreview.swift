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
    private static let side: CGFloat = 104
    private static let kind: AvatarKind = .group

    private let picture: GroupPictureEdit
    /// The photo on the server, shown while the edit has not touched it.
    private let savedPictureURL: String?

    init(
        _ picture: GroupPictureEdit,
        savedPictureURL: String?
    ) {
        self.picture = picture
        self.savedPictureURL = savedPictureURL
    }

    var body: some View {
        AvatarThumbnail(
            Self.kind,
            imageUrl: picture == .unchanged ? savedPictureURL : nil,
            side: Self.side
        )
        .overlay {
            if let data = picture.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.side, height: Self.side)
                    .clipShape(RoundedRectangle(cornerRadius: Self.kind.cornerRadius))
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview("No photo") {
    GroupPhotoPreview(.unchanged, savedPictureURL: nil)
}

#Preview("Removed") {
    GroupPhotoPreview(.removed, savedPictureURL: "https://inventaire.io/img/groups/abc")
}
