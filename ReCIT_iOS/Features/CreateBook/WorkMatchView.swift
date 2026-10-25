//
//  WorkMatchView.swift
//  ReCIT_iOS
//
//  « Œuvre déjà connue » — the search did not offer it, but inventaire.io recognises the work
//  being created by its title and its author. The screen that stands between a reader and a
//  second work of the same name. Frame `V6` of « Nouveau livre v2 » in the Figma file.
//
//  It is shown only when the reconnaissance pass recognised a work — the `resolve` call made
//  with `create: false`, which writes nothing — and only on the way to creating one: a work
//  picked from the search is named by its uri and needs no such pass.
//
//  The work is drawn from SwiftData, refreshed on appearance, as ADR 0001 asks: the model
//  layer answered a uri, the view reads the object. Which is also why the title shown here can
//  differ from the one typed in the form — that is the point of the screen.
//
//  See PRD 0015 and PRD 0021.
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

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    /// Publishes with whatever has just been decided.
    let onPublish: () async -> Void
    let onClose: () -> Void

    @State private var work: Work?

    /// The work as the row draws it: the one inventaire.io has once it has been read, and until
    /// then what the reader typed — the same title, give or take a capital.
    private var candidate: WorkCandidate {
        if let work {
            .init(work: work)
        } else {
            .init(
                uri: workUri,
                title: draft.trimmedWorkTitle,
                authors: draft.namedAuthors.map(\.trimmedName),
                year: nil,
                summary: nil,
                imageUrl: nil
            )
        }
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
                WorkRow(work: candidate)
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
                Text("create_book.work.what_you_publish")
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
        .navigationTitle(String(localized: "create_book.work.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // The default answer is the safe one: one more edition of the work that exists.
            // Set before the fetch, so a reader who publishes straight away gets it.
            draft.workUri = workUri
            draft.hasAnsweredWorkQuestion = true

            work = try? await entityModel.refreshWork(modelContext: modelContext, uri: workUri)
        }
        .onDisappear {
            // Back to « Nouvelle œuvre » without publishing: the question goes with the screen,
            // so the work being described is the reader's own again, and the next publication
            // asks anew.
            if draft.workUri == workUri, draft.chosenWork == nil {
                draft.workUri = nil
                draft.hasAnsweredWorkQuestion = false
            }
        }
    }
}

/// One of the two answers, with what it costs written under it. `Form / Choice Row` (`701:555`)
/// in the Figma file.
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
