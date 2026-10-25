//
//  NewEditionWorkSection.swift
//  ReCIT_iOS
//
//  « Édition de » in the scanner's « Nouvelle édition »: the one work the new book is an edition
//  of. A work inventaire.io has is touched to go back to the search for another; one being
//  described is touched to name it and its authors. Either is detached with a swipe, and the
//  section then offers to find one — a book is published as an edition of a work, or not at all.
//

import SwiftUI

struct NewEditionWorkSection: View {
    @Binding var draft: NewBookDraft
    /// Back to the work search.
    let onFindWork: () -> Void
    /// Pushes the screen of the work being described.
    let onOpenNewWork: () -> Void

    private var footer: LocalizedStringKey {
        if draft.chosenWork != nil { return "create_book.edition.of_help" }
        if draft.hasWork { return "create_book.edition.new_work_help" }
        return "create_book.edition.no_work_help"
    }

    /// The work being described, as the row draws it.
    private var newWork: WorkCandidate {
        .init(
            uri: "",
            title: draft.trimmedWorkTitle,
            authors: draft.namedAuthors.map(\.trimmedName),
            year: nil,
            summary: nil,
            imageUrl: nil
        )
    }

    var body: some View {
        Section {
            if let work = draft.chosenWork {
                Button(action: onFindWork) {
                    WorkRow(work: work, showsDisclosure: true)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) { detach }
                .accessibilityIdentifier("e2e.createBook.edition.work")
            } else if draft.hasWork {
                Button(action: onOpenNewWork) {
                    WorkRow(work: newWork, showsDisclosure: true)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) { detach }
                .accessibilityIdentifier("e2e.createBook.edition.newWork")
            } else {
                EditEditionActionRow(title: "edit_edition.works.add", action: onFindWork)
                    .accessibilityIdentifier("e2e.createBook.edition.addWork")
            }
        } header: {
            CreateBookSectionHeader("create_book.edition.of")
        } footer: {
            CreateBookSectionFooter(footer)
        }
    }

    private var detach: some View {
        Button("edit_edition.works.detach", role: .destructive) {
            draft.detachWork()
        }
        .tint(.foregroundError)
    }
}
