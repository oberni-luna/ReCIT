//
//  EditEditionView.swift
//  ReCIT_iOS
//
//  « Modifier l'édition » — the form behind the « Modifier » of the book screen's « Données
//  bibliographiques ». The shape of `V3 · Nouvelle édition` in the Figma file, filled with what
//  inventaire.io holds: the cover, the ISBN shown and not editable, the title, the subtitle.
//
//  « Enregistrer » sits at the foot, as « Publier » does in the creation forms, and waits for
//  the server: `EntityCreationModel` says why nothing about writing into the open database is
//  optimistic. It stays disabled until something has changed, and while the title is empty.
//

import SwiftUI

struct EditEditionView: View {
    @Binding var edit: EditionEdit

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onSave: () async -> Void

    /// Pushes « Image depuis une URL » for the cover.
    let onPickCoverURL: () -> Void

    var body: some View {
        Form {
            if let failure {
                Section {
                    CreateBookFailureBanner(
                        title: failure.editionEditTitle,
                        explanation: failure.editionEditExplanation
                    )
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }

            BibliographicDataNotice()

            Section {
                CreateBookCoverRow(
                    isbn: edit.original.isbn,
                    isbnLabel: "edit_edition.isbn",
                    imageData: $edit.coverData,
                    onPickURL: onPickCoverURL
                )
            }

            Section {
                TextField("create_book.title_field", text: $edit.title)
                    .accessibilityIdentifier("e2e.editEdition.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.title_field")

                TextField("edit_edition.subtitle_field", text: $edit.subtitle, axis: .vertical)
                    .accessibilityIdentifier("e2e.editEdition.subtitle")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "edit_edition.subtitle_field")
            }

            Section {} footer: {
                AsyncButton(
                    action: onSave,
                    actionOptions: [.showProgressView],
                    label: {
                        Text(failure?.isWorthRetrying == true ? "create_book.retry" : "action.save")
                            .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.primary())
                .disabled(edit.isSaveable == false)
                .accessibilityIdentifier("e2e.editEdition.save")
            }
        }
        .applyListBackground()
        .bibliographicDataHelpButton()
    }
}
