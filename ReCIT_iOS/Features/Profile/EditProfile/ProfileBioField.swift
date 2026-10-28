//
//  ProfileBioField.swift
//  ReCIT_iOS
//
//  The bio, typed over several lines, with what it weighs against the server's 1 000 characters
//  under it (`Form / Text Area`). Past the limit the count turns red and « Enregistrer » greys out:
//  the server would refuse it anyway.
//

import SwiftUI

struct ProfileBioField: View {
    @Binding var draft: ProfileDraft

    var body: some View {
        VStack(alignment: .trailing, spacing: .xSmall) {
            TextField("edit_profile.bio.placeholder", text: $draft.bio, axis: .vertical)
                .lineLimit(3...)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .accessibilityIdentifier("e2e.editProfile.bio")
                .frame(maxWidth: .infinity, alignment: .leading)
                .withLabel(label: "edit_profile.bio")

            Text("edit_profile.bio.count \(draft.bioLength) \(ProfileDraft.bioLimit)")
                .textStyle(.footnote200)
                .foregroundStyle(draft.isBioTooLong ? .foregroundError : .foregroundSecondary)
                .monospacedDigit()
        }
    }
}
