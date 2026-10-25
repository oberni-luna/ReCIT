//
//  NewWorkView.swift
//  ReCIT_iOS
//
//  « Nouvelle œuvre » — the work the new book is an edition of, when the search found none: its
//  title and who wrote it. Pushed over « Nouvelle édition » when « Créer l'œuvre » is chosen, and
//  from its row afterwards; the shape of `E5` in the Figma section `Modifier l'édition · Toutes
//  les données`. Nothing is published from here: the edition's form publishes the work with it.
//
//  See PRD 0026 and PRD 0027.
//

import SwiftUI

struct NewWorkView: View {
    @Binding var draft: NewBookDraft

    /// The work's title, written through the draft so the edition's can follow it.
    private var workTitle: Binding<String> {
        .init(
            get: { draft.workTitle },
            set: { draft.renameWork($0) }
        )
    }

    var body: some View {
        Form {
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
                CreateBookSectionHeader("create_book.new_work.section")
            } footer: {
                CreateBookSectionFooter("create_book.new_work.help")
            }
        }
        .applyListBackground()
        .navigationTitle(String(localized: "create_book.new_work.title"))
        .navigationBarTitleDisplayMode(.inline)
        .bibliographicDataHelpButton()
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
