//
//  GroupPhotoPicker.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// The first section of « Réglages du groupe »: the group's photo, and the menu of where a new one
/// can come from — the same as an edition's cover. It only changes the edit: nothing is uploaded
/// before « Enregistrer ».
struct GroupPhotoPicker: View {
    /// The photo on the server, shown while the edit has not touched it.
    private let savedPictureURL: String?
    /// Pushes « Image depuis une URL » onto the sheet's navigation stack.
    private let onPickURL: () -> Void

    @Binding private var picture: GroupPictureEdit

    init(
        _ picture: Binding<GroupPictureEdit>,
        savedPictureURL: String?,
        onPickURL: @escaping () -> Void
    ) {
        _picture = picture
        self.savedPictureURL = savedPictureURL
        self.onPickURL = onPickURL
    }

    private var showsPicture: Bool {
        picture.showsPicture(savedPictureURL: savedPictureURL)
    }

    var body: some View {
        ImageSourceMenu(
            "groups.form.picture.remove",
            hasImage: showsPicture,
            onPick: { picture = .replaced($0) },
            onRemove: { picture = .removed },
            onPickURL: onPickURL,
            label: {
                VStack(spacing: .small) {
                    GroupPhotoPreview(picture: picture, savedPictureURL: savedPictureURL)

                    Text(showsPicture ? "groups.form.picture.change" : "groups.form.picture.add")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                }
                .frame(maxWidth: .infinity)
            }
        )
        .accessibilityIdentifier(AccessibilityID.picture)
    }
}

private extension GroupPhotoPicker {
    enum AccessibilityID {
        static let picture: String = "e2e.groupSettings.picture"
    }
}

#Preview("No photo") {
    @Previewable @State var picture: GroupPictureEdit = .unchanged

    DesignSystem.Form {
        Section {
            GroupPhotoPicker($picture, savedPictureURL: nil, onPickURL: {})
        }
        .listRowBackground(Color.clear)
    }
}

#Preview("Photo taken away") {
    @Previewable @State var picture: GroupPictureEdit = .removed

    DesignSystem.Form {
        Section {
            GroupPhotoPicker($picture, savedPictureURL: "https://inventaire.io/img/groups/abc", onPickURL: {})
        }
        .listRowBackground(Color.clear)
    }
}
