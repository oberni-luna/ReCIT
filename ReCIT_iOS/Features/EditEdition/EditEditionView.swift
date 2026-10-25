//
//  EditEditionView.swift
//  ReCIT_iOS
//
//  « Modifier l'édition » — the form behind the « Modifier » of the book screen's « Données
//  bibliographiques ». The shape of `V3 · Nouvelle édition` in the Figma file, filled with what
//  inventaire.io holds: the work it is an edition of, the cover, the ISBN shown and not
//  editable, the title, the subtitle.
//
//  « Édition de » comes first, as in `V3`, and does more here: the work is changed through the
//  same search as a new book's (`V2`), or created when the search finds none — titled in place,
//  given authors below it. Authors are added to an existing work the same way, through the
//  creation's author search; those added are listed until saved, and can be swiped away.
//
//  Under the title, every other property inventaire.io accepts on an edition (`EditionProperty`):
//  « Publication », « Format », « Ont aussi fait cette édition », « Bases bibliographiques » and
//  « Autres données » — `E1` of the Figma section `Modifier l'édition · Toutes les données`.
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

    /// Pushes the search for the edition's work.
    let onChooseWork: () -> Void

    /// Pushes the search for an author to add to the work.
    let onAddAuthor: () -> Void

    /// Pushes « Image depuis une URL » for the cover.
    let onPickCoverURL: () -> Void
    /// Pushes the screen that changes one property of the catalogue: an entity's, the date.
    let onOpenProperty: (EditionProperty) -> Void
    /// Pushes the list of catalogues an identifier — or a link — is added to.
    let onAddIdentifier: (EditionProperty.Group) -> Void

    private var workFooter: LocalizedStringKey {
        if edit.isCreatingWork { return "edit_edition.work.new_help" }
        if edit.work?.isEditable == false { return "edit_edition.work.wikidata_help" }
        return "edit_edition.work.help"
    }

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
                if edit.isCreatingWork {
                    TextField("create_book.new_work.title_field", text: $edit.newWorkTitle)
                        .accessibilityIdentifier("e2e.editEdition.workTitle")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "create_book.new_work.title_field")
                } else if let work = edit.work {
                    Button(action: onChooseWork) {
                        WorkRow(work: work.candidate, showsDisclosure: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("e2e.editEdition.work")
                }

                ForEach(edit.addedAuthors) { author in
                    EditEditionAddedAuthorRow(author: author)
                }
                .onDelete { offsets in
                    edit.removeAddedAuthors(atOffsets: offsets)
                }

                if edit.canAddAuthors {
                    EditEditionActionRow(title: "edit_edition.work.add_author", action: onAddAuthor)
                        .accessibilityIdentifier("e2e.editEdition.addAuthor")
                }

                if edit.work == nil {
                    EditEditionActionRow(
                        title: edit.isCreatingWork ? "edit_edition.work.change" : "edit_edition.work.choose",
                        action: onChooseWork
                    )
                    .accessibilityIdentifier("e2e.editEdition.chooseWork")
                }
            } header: {
                CreateBookSectionHeader("create_book.edition.of")
            } footer: {
                CreateBookSectionFooter(workFooter)
            }

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
