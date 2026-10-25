//
//  EditEditionView.swift
//  ReCIT_iOS
//
//  « Modifier l'édition » — the form behind the book screen's « Données bibliographiques »:
//  everything inventaire.io holds about an edition, filled from the server. Frame `E1` of the
//  Figma section `Modifier l'édition · Toutes les données`.
//
//  « Édition de » comes first: the works the edition is an edition of, each opening « Modifier
//  l'œuvre », detached with a swipe, added through the same search as a new book's (`V2`) or
//  created when it finds none. Then the cover and ISBN — shown, not editable —, the title and
//  the subtitle, and every other property of the catalogue (`EditionProperty`): « Publication »,
//  « Format », « Ont aussi fait cette édition », « Bases bibliographiques » and « Sur le web ».
//
//  « Enregistrer » is pinned at the foot of the sheet (`E3`), and waits for the server:
//  `EntityCreationModel` says why nothing about writing into the open database is optimistic. It
//  stays disabled until something has changed, and while the title is empty.
//

import SwiftUI

struct EditEditionView: View {
    @Binding var edit: EditionEdit

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onSave: () async -> Void

    /// Pushes the search for a work to add.
    let onAddWork: () -> Void

    /// Pushes « Modifier l'œuvre » for the work with this id.
    let onOpenWork: (UUID) -> Void

    /// Pushes « Image depuis une URL » for the cover.
    let onPickCoverURL: () -> Void
    /// Pushes the screen that changes one property of the catalogue: an entity's, the date.
    let onOpenProperty: (EditionProperty) -> Void
    /// Pushes the list of catalogues an identifier — or a link — is added to.
    let onAddIdentifier: (EditionProperty.Group) -> Void

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

            EditionWorksSection(
                works: edit.works,
                onOpen: onOpenWork,
                onDetach: { edit.detachWork(id: $0) },
                onAdd: onAddWork
            )

            Section {
                CreateBookCoverRow(
                    isbn: edit.original.isbn,
                    isbnLabel: edit.original.isbn10 == nil ? "edit_edition.isbn" : "edit_edition.isbn13",
                    isbn10: edit.original.isbn10,
                    imageData: $edit.coverData,
                    onPickURL: onPickCoverURL
                )
            } header: {
                CreateBookSectionHeader("edit_edition.cover.header")
            } footer: {
                CreateBookSectionFooter("edit_edition.cover.footer")
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
            } header: {
                CreateBookSectionHeader("edit_edition.title.header")
            }

            EditionPublicationSection(properties: edit.properties, onOpen: onOpenProperty)

            EditionFormatSection(properties: $edit.properties)

            EditionContributorsSection(properties: edit.properties, onOpen: onOpenProperty)

            EditionIdentifiersSection(group: .databases, properties: $edit.properties) {
                onAddIdentifier(.databases)
            }

            EditionIdentifiersSection(group: .links, properties: $edit.properties) {
                onAddIdentifier(.links)
            }
        }
        .applyListBackground()
        .safeAreaInset(edge: .bottom) {
            EditEditionSaveBar(
                title: failure?.isWorthRetrying == true ? "create_book.retry" : "action.save",
                isEnabled: edit.isSaveable,
                onSave: onSave
            )
        }
        .bibliographicDataHelpButton()
    }
}
