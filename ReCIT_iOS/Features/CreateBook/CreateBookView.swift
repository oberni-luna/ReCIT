//
//  CreateBookView.swift
//  ReCIT_iOS
//
//  The form that describes a book none of the works found fits: the title printed on this
//  cover, and its author. Pushed from the work search's « créer l'œuvre », with the title
//  searched for already in it.
//
//  Two fields, no more — see `NewBookDraft` for why those two.
//
//  See PRD 0015 and PRD 0021.
//

import SwiftUI

struct CreateBookView: View {
    @Binding var draft: NewBookDraft

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onPublish: () async -> Void
    let onClose: () -> Void

    var body: some View {
        Form {
            if let failure {
                Section {
                    CreateBookFailureBanner(failure: failure)
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }

            Section {
                CreateBookCoverRow(draft: $draft)
            } footer: {
                CreateBookEditionNotes(draft: draft)
            }
            .listRowSeparator(.visible)
            .listSectionSeparator(.hidden)

            Section {
                TextField("create_book.title_field", text: $draft.title)
                    .accessibilityIdentifier("e2e.createBook.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.title_field")

                NavigationLink {
                    AuthorPickerView(draft: $draft)
                } label: {
                    CreateBookAuthorRow(draft: draft)
                }
                .accessibilityIdentifier("e2e.createBook.author")
            } footer: {
                Text("create_book.title_help")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
            .listRowSeparator(.visible)
            .listSectionSeparator(.hidden)

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
        .navigationTitle(String(localized: "create_book.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The author line of the form: who has been chosen, or an invitation to choose.
///
/// A row rather than a text field, since issue 0093. Typing a name straight in is what makes a
/// second « Ursula K. Le Guin »; going through a screen that shows the existing ones first is
/// what does not.
private struct CreateBookAuthorRow: View {
    let draft: NewBookDraft

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text("create_book.author_field")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)

            if draft.trimmedAuthorName.isEmpty {
                Text("create_book.author.choose")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundPlaceholder)
            } else {
                Text(draft.trimmedAuthorName)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if let description = draft.authorDescription, description.isEmpty == false {
                    Text(description)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
