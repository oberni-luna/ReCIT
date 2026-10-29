//
//  NewEditionView.swift
//  ReCIT_iOS
//
//  « Nouvelle édition » — the book in hand, described with the same form as « Modifier
//  l'édition »: frame `E2` of the Figma section `Modifier l'édition · Toutes les données`. It
//  replaces `V3`, and the edition half of `V5`, of « Nouveau livre v2 ».
//
//  « Édition de » holds the work found by the search, or the one being described, whose title
//  and authors are named on its own screen. Then the cover and the ISBN the camera read, the
//  title — starting as the work's — and the subtitle, and every other property inventaire.io
//  accepts on an edition, the language already filled in from the ISBN. « Publier et ajouter à
//  mes livres » is pinned at the foot of the sheet.
//
//  See PRD 0026 and PRD 0027.
//

import SwiftUI

struct NewEditionView: View {
    @Binding var draft: NewBookDraft

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onPublish: () async -> Void
    let onClose: () -> Void

    /// Pushes « Image depuis une URL » for the cover.
    let onPickCoverURL: () -> Void
    /// Back to the work search.
    let onFindWork: () -> Void
    /// Pushes the screen of the work being described.
    let onOpenNewWork: () -> Void
    /// Pushes the screen that changes one property of the catalogue.
    let onOpenProperty: (EditionProperty) -> Void
    /// Pushes the list of catalogues an identifier — or a link — is added to.
    let onAddIdentifier: (EditionProperty.Group) -> Void

    var body: some View {
        DesignSystem.Form {
            if let failure {
                Section {
                    CreateBookFailureBanner(failure: failure)
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }

            BibliographicDataNotice()

            NewEditionWorkSection(draft: $draft, onFindWork: onFindWork, onOpenNewWork: onOpenNewWork)

            Section {
                CreateBookCoverRow(isbn: draft.isbn, imageData: $draft.cover, onPickURL: onPickCoverURL)
            } header: {
                CreateBookSectionHeader("edit_edition.cover.header")
            } footer: {
                CreateBookEditionNotes(draft: draft)
            }

            Section {
                TextField("create_book.title_field", text: $draft.title)
                    .accessibilityIdentifier("e2e.createBook.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.title_field")

                TextField("edit_edition.subtitle_field", text: $draft.subtitle, axis: .vertical)
                    .accessibilityIdentifier("e2e.createBook.subtitle")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "edit_edition.subtitle_field")
            } header: {
                CreateBookSectionHeader("edit_edition.title.header")
            } footer: {
                CreateBookSectionFooter("create_book.edition.title_help")
            }

            EditionPublicationSection(properties: draft.properties, onOpen: onOpenProperty)

            EditionFormatSection(properties: $draft.properties)

            EditionContributorsSection(properties: draft.properties, onOpen: onOpenProperty)

            EditionIdentifiersSection(group: .databases, properties: $draft.properties) {
                onAddIdentifier(.databases)
            }

            EditionIdentifiersSection(group: .links, properties: $draft.properties) {
                onAddIdentifier(.links)
            }
        }
        .formActionBar {
            CreateBookPublishFooter(
                failure: failure,
                isPublishable: draft.isPublishable,
                onPublish: onPublish,
                onClose: onClose
            )
        }
        .navigationTitle(String(localized: "create_book.edition.title"))
        .navigationBarTitleDisplayMode(.inline)
        .bibliographicDataHelpButton()
    }
}
