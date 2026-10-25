//
//  EditEditionSaveBar.swift
//  ReCIT_iOS
//
//  « Enregistrer », pinned at the foot of the sheet (`safeAreaInset(edge: .bottom)`): the form is
//  long, and saving it must not mean scrolling to its end. `Action Bar / Attached` in the Figma
//  file without its two round buttons: `background/default`, a hairline above, the primary
//  button across the width.
//

import SwiftUI

struct EditEditionSaveBar: View {
    let title: LocalizedStringKey
    let isEnabled: Bool
    let onSave: () async -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

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
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
            .accessibilityIdentifier("e2e.editEdition.save")
        }
        .background(.backgroundDefault)
    }
}
