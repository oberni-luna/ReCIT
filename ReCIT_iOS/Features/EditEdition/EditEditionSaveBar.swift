//
//  EditEditionSaveBar.swift
//  ReCIT_iOS
//
//  « Enregistrer », pinned at the foot of the sheet through `formActionBar(_:)`: the form is long,
//  and saving it must not mean scrolling to its end. The primary button across the width.
//

import SwiftUI

struct EditEditionSaveBar: View {
    let title: LocalizedStringKey
    let isEnabled: Bool
    let onSave: () async -> Void

    var body: some View {
        AsyncButton(
            action: onSave,
            actionOptions: [.showProgressView],
            label: {
                Text(title)
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.primary())
        .disabled(isEnabled == false)
        .accessibilityIdentifier("e2e.editEdition.save")
    }
}
