//
//  NewWorkView.swift
//  ReCIT_iOS
//
//  « Nouvelle œuvre » — none of the works found was the book, so the work is described along
//  with the edition, in one form. Frame `V5` of « Nouveau livre v2 » in the Figma file; it
//  replaces the two-field form of PRD 0015.
//
//  The work first: its title, carried over from the search, and who wrote it — one author or
//  several, each picked from inventaire.io or created. Then this edition: its cover, its ISBN,
//  and its title, which follows the work's until the reader makes it their own.
//
//  See PRD 0021.
//

import SwiftUI

struct NewWorkView: View {
    @Binding var draft: NewBookDraft

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onPublish: () async -> Void
    let onClose: () -> Void

    /// Pushes « Image depuis une URL » for the cover.
    let onPickCoverURL: () -> Void

    /// The work's title, written through the draft so the edition's can follow it.
    private var workTitle: Binding<String> {
        .init(
            get: { draft.workTitle },
            set: { draft.renameWork($0) }
        )
    }

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
                TextField("create_book.new_work.title_field", text: workTitle)
                    .accessibilityIdentifier("e2e.createBook.workTitle")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.new_work.title_field")

                if draft.authors.isEmpty {
                    NavigationLink {
                        AuthorPickerView(initialQuery: "") { author in
                            draft.authors.append(author)
                        }
                    } label: {
                        NewWorkAuthorRow(author: nil)
                    }
                    .accessibilityIdentifier("e2e.createBook.author")
                } else {
                    ForEach($draft.authors) { $author in
                        NavigationLink {
                            AuthorPickerView(initialQuery: author.name) { chosen in
                                author = chosen
                            }
                        } label: {
                            NewWorkAuthorRow(author: author)
                        }
                        .accessibilityIdentifier("e2e.createBook.author")
                    }
                    .onDelete { offsets in
                        draft.authors.remove(atOffsets: offsets)
                    }
                    // A work being created needs someone who wrote it: the last author goes by
                    // being replaced, not by being deleted.
                    .deleteDisabled(draft.authors.count <= 1)

                    NavigationLink {
                        AuthorPickerView(initialQuery: "") { author in
                            draft.authors.append(author)
                        }
                    } label: {
                        Label("create_book.new_work.add_author", systemImage: "plus")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundTinted)
                    }
                    .accessibilityIdentifier("e2e.createBook.addAuthor")
                }
            } header: {
                Text("create_book.new_work.section")
            } footer: {
                Text("create_book.new_work.help")
            }

            Section {
                CreateBookCoverRow(draft: $draft, onPickURL: onPickCoverURL)

                TextField("create_book.title_field", text: $draft.title)
                    .accessibilityIdentifier("e2e.createBook.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.title_field")
            } header: {
                Text("create_book.new_work.edition_section")
            } footer: {
                CreateBookEditionNotes(draft: draft, notice: "create_book.new_work.public_notice")
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
        .navigationTitle(String(localized: "create_book.new_work.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One author line of the work: who has been chosen, or an invitation to choose. `Form / Author
/// Row` (`701:536`) in the Figma file.
///
/// A row rather than a text field, since issue 0093. Typing a name straight in is what makes a
/// second « Ursula K. Le Guin »; going through a screen that shows the existing ones first is
/// what does not.
private struct NewWorkAuthorRow: View {
    let author: NewBookAuthor?

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text("create_book.author_field")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)

            if let author, author.trimmedName.isEmpty == false {
                Text(author.trimmedName)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if let description = author.description, description.isEmpty == false {
                    Text(description)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(2)
                }
            } else {
                Text("create_book.author.choose")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundPlaceholder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
