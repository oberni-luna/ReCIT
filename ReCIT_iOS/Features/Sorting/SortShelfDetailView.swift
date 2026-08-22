//
//  SortShelfDetailView.swift
//  ReCIT_iOS
//
//  An étagère opened as it **will be**, not as the server holds it: the books it already has
//  plus the ones this session has filed into it, in the order the card's pile shows them.
//
//  **Why not `ShelfDetailView`.** That screen looks its subject up by server `_id` through a
//  `@Query`, and a draft étagère has no server document — it would show an empty title over an
//  empty list. Its swipe is also an immediate optimistic write, which is the one thing this
//  session must not do. Two hard reasons, so two screens.
//
//  **Swiping takes a book off the étagère and nothing more.** It records a move into « à
//  ranger » — no server call, no inventory deletion — so the book reappears among the books to
//  file and the recap follows. The action is neither red nor destructive, for the reason
//  `ShelfDetailView` already states: nothing is deleted, the copy stays in the inventory and on
//  every other étagère, and red would teach the user to fear an action that costs one tap to
//  undo.
//
//  It renders from the session's projection, so it is reactive without SwiftData: the app-scoped
//  model is `@Observable`, and a screen pushed over the surface reads the same derivation the
//  surface does. That is what PRD 0009 chose over storing pending membership with a dirty flag.
//
//  **It pops when its section stops existing** — an apply lands the draft under a new id, or the
//  stack is discarded from the surface underneath. Both are reachable because the session
//  outlives this screen.
//
//  See PRD 0009.
//

import SwiftUI

struct SortShelfDetailView: View {
    @Environment(SortSessionModel.self) private var session
    @Environment(\.dismiss) private var dismiss

    let sectionId: SortSection.ID

    var body: some View {
        let section: SortSection? = session.projection.sections.first { $0.id == sectionId }

        return List {
            if let section {
                if section.books.isEmpty {
                    Text("manual_sort.shelf.detail.empty")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                } else {
                    ForEach(section.books) { book in
                        SortBookRow(book: book)
                            // Full swipe on: the change is cheap and reversible — it is not
                            // even sent yet — and clearing several books off an étagère should
                            // not cost a tap each.
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(
                                    "action.remove_from_shelf_named \(section.name ?? "")",
                                    systemImage: "tray.and.arrow.up"
                                ) {
                                    unshelve(book, from: section)
                                }
                                .disabled(session.isBusy)
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .applyListBackground()
        .navigationTitle(section?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        // Reactive rather than signalled: unlike `ShelfDetailView`, which pops on a form's own
        // word because a background sync must not pop a screen the user is deep behind, this
        // screen is only ever the top of the sorting flow — so the disappearance itself is the
        // signal, and staying would leave a title over an empty list.
        .onChange(of: section == nil) { _, hasGone in
            guard hasGone else { return }
            dismiss()
        }
    }

    /// Takes one book off this étagère: a move into « à ranger », on the stack, and nothing
    /// else. Refused while a run owns the stack, like every other change.
    private func unshelve(_ book: AutoSortBook, from section: SortSection) {
        session.moveBook(book.id, from: section.id, to: .unshelved)
    }
}
