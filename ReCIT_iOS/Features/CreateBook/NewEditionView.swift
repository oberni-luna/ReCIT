//
//  NewEditionView.swift
//  ReCIT_iOS
//
//  « Nouvelle édition » — the book in hand is an edition of a work inventaire.io already has.
//  Frame `V3` of « Nouveau livre v2 » in the Figma file.
//
//  The work and its authors came from the search: nothing to type again, and nothing to ask
//  the reconnaissance pass, since the work is named by its uri. What is left is this edition —
//  its cover, its ISBN, and its title, which starts as the work's.
//
//  See PRD 0021.
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

    var body: some View {
        Form {
            if let failure {
                Section {
                    CreateBookFailureBanner(failure: failure)
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }

            if let work = draft.chosenWork {
                Section {
                    WorkRow(work: work)
                        .accessibilityIdentifier("e2e.createBook.edition.work")
                } header: {
                    Text("create_book.edition.of")
                } footer: {
                    Text("create_book.edition.of_help")
                }
            }

            Section {
                CreateBookCoverRow(draft: $draft, onPickURL: onPickCoverURL)
            } footer: {
                CreateBookEditionNotes(draft: draft)
            }

            Section {
                TextField("create_book.title_field", text: $draft.title)
                    .accessibilityIdentifier("e2e.createBook.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.title_field")
            } footer: {
                Text("create_book.edition.title_help")
            }

            Section {} footer: {
                CreateBookPublishFooter(
                    failure: failure,
                    isPublishable: draft.isPublishable,
                    onPublish: onPublish,
                    onClose: onClose
                )
            }
        }
        .applyListBackground()
        .navigationTitle(String(localized: "create_book.edition.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
