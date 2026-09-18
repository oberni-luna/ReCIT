//
//  WorkMatchView.swift
//  ReCIT_iOS
//
//  « inventaire.io knows this book, but not this edition. » The screen that stands between a
//  reader and a second work of the same name.
//
//  It is shown only when the reconnaissance pass recognised a work — the `resolve` call made
//  with `create: false`, which writes nothing. When nothing was recognised the reader never
//  sees it and the book is published straight away.
//
//  The work is drawn from SwiftData, refreshed on appearance, as ADR 0001 asks: the model
//  layer answered a uri, the view reads the object. Which is also why the title shown here can
//  differ from the one typed in the form — that is the point of the screen.
//
//  See PRD 0015.
//

import SwiftUI
import SwiftData

struct WorkMatchView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(\.modelContext) private var modelContext

    let workUri: String

    /// Set by the two choices, and read by the publication that follows. Bound rather than
    /// copied: the answer belongs to the draft, which survives this screen.
    @Binding var draft: NewBookDraft

    /// Publishes with whatever has just been decided.
    let onPublish: () async -> Void

    @State private var work: Work?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(work?.title ?? draft.trimmedTitle)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    if let authors = work?.authors, authors.isEmpty == false {
                        Text(authors.map(\.name).joined(separator: ", "))
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundSecondary)
                    }
                }
                .accessibilityIdentifier("e2e.createBook.work")
            } header: {
                Text("create_book.work.header")
            } footer: {
                Text("create_book.work.lead")
            }

            Section {
                WorkMatchChoice(
                    title: "create_book.work.one_more_edition",
                    explanation: "create_book.work.one_more_edition_help",
                    isSelected: draft.workUri != nil
                ) {
                    draft.workUri = workUri
                }
                .accessibilityIdentifier("e2e.createBook.work.sameWork")

                WorkMatchChoice(
                    title: "create_book.work.another_book",
                    explanation: "create_book.work.another_book_help",
                    isSelected: draft.workUri == nil
                ) {
                    draft.workUri = nil
                }
                .accessibilityIdentifier("e2e.createBook.work.otherWork")
            } header: {
                Text("create_book.work.what_you_create")
            }

            Section {} footer: {
                AsyncButton(
                    action: onPublish,
                    actionOptions: [.showProgressView],
                    label: {
                        Text("create_book.work.publish_edition")
                            .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.createBook.work.publish")
            }
        }
        .applyListBackground()
        .navigationTitle(String(localized: "create_book.work.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // The default answer is the safe one: one more edition of the work that exists.
            // Set before the fetch, so a reader who publishes straight away gets it.
            draft.workUri = workUri
            draft.hasAnsweredWorkQuestion = true

            work = try? await entityModel.refreshWork(modelContext: modelContext, uri: workUri)
        }
    }
}

/// One of the two answers, with what it costs written under it.
private struct WorkMatchChoice: View {
    let title: LocalizedStringKey
    let explanation: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: .sMedium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .foregroundTinted : .foregroundSecondary)

                VStack(alignment: .leading, spacing: .xxSmall) {
                    Text(title)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    Text(explanation)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
