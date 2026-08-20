//
//  SortProposal.swift
//  ReCIT_iOS
//
//  What the on-device model proposed, turned into ordinary changes on the sorting
//  surface's stack.
//
//  **The model becomes one change generator among others.** Its output lands on the
//  same ordered stack a drag lands on, so the proposal is editable by dragging,
//  « Annuler » discards it like any other pending work, and it can be asked for again
//  after sorting by hand. That closes the gap PRD 0006 left open, where a plan could
//  only be accepted or refused whole.
//
//  **Reconciliation happens here, in plain code.** A proposed name whose comparison key
//  matches a section the user is already looking at becomes a move *into* that section
//  instead of a creation. Auto-sort never saw the user's existing étagères — it is
//  scoped to unshelved books and knows nothing else — but on this screen they are right
//  there, so asking for help must not duplicate them. Drafts already on the stack count
//  too: asking twice would otherwise make two drafts of one name, which
//  `SortDraftNameRule` refuses by hand and would be absurd to allow by machine.
//
//  The comparison is `AutoSortName`'s key — trimmed, case- and diacritic-insensitive —
//  and not a second one written here, for the reason `SortDraftNameRule` states: two
//  names a reader cannot tell apart are one étagère, and there must be exactly one
//  meaning of that across the app.
//
//  Three things this deliberately does *not* do:
//
//  - **A book the plan files where it already sits pushes nothing.** The no-op belongs
//    to `SortChange.move`, which returns `nil` for a drop back on the origin, so asking
//    again after sorting by hand cannot re-file what is already filed.
//  - **A proposed étagère that would end up empty is not drafted.** A create with no
//    move behind it would put a section on screen carrying « Nouvelle » that the write
//    plan then drops and the recap names as lost — a shelf the user never asked for and
//    is then told they will not get.
//  - **`leftUnshelved` yields nothing at all.** Those books stay exactly where the user
//    put them; a proposal is additive, and dragging a book *into* the pile is a gesture
//    only the user makes.
//
//  Creations are appended before the moves that name them, because `SortProjection`
//  ignores a move naming a section it does not yet know.
//
//  Pure by design — no store, no network, no model, no SwiftUI. See PRD 0008.
//

import Foundation

struct SortProposal: Equatable, Sendable {

    /// The changes to lay on the stack, in the order they must be applied. Empty when
    /// the model proposed nothing the surface does not already have.
    let changes: [SortChange]

    /// Built from a plan and **the sections the surface is showing** — which is to say
    /// the projection, existing étagères and drafts alike, resolved in the one place
    /// that resolves them. Reading the snapshot instead would reconcile against the
    /// library as it stood on arrival and miss everything sorted since.
    init(
        plan: AutoSortPlan,
        sections: [SortSection]
    ) {
        // Where each book sits right now — the origin half of every move. The
        // projection guarantees exactly one section per book, so this is a lookup and
        // never a choice.
        var sectionOfBook: [String: SortSection.ID] = [:]

        // Comparison key → the section that already reads under that name. First
        // occurrence wins, the same order the user read them in.
        var sectionByNameKey: [String: SortSection.ID] = [:]

        for section in sections {
            for book in section.books {
                sectionOfBook[book.id] = section.id
            }
            guard section.isUnshelved == false,
                  let name = section.name,
                  let key = AutoSortName.key(name),
                  sectionByNameKey[key] == nil else { continue }
            sectionByNameKey[key] = section.id
        }

        var changes: [SortChange] = []

        for proposed in plan.shelves {
            // A blank name cannot become an étagère, here no more than at the form.
            guard let name = AutoSortName.trimmed(proposed.name),
                  let key = AutoSortName.key(name) else { continue }

            let destination: SortSection.ID
            let draftId: String?
            if let existing = sectionByNameKey[key] {
                destination = existing
                draftId = nil
            } else {
                let id: String = SortDraftID.make()
                draftId = id
                destination = .draft(id)
            }

            // A book the surface does not show cannot be moved: the plan is built from
            // the store and the surface from a frozen snapshot, so a copy that left the
            // inventory since is named by one and not the other.
            let moves: [SortChange] = proposed.books.compactMap { book in
                guard let origin = sectionOfBook[book.id] else { return nil }
                return .move(bookId: book.id, from: origin, to: destination)
            }

            if let draftId {
                guard moves.isEmpty == false else { continue }
                changes.append(.createShelf(draftId: draftId, name: name))
                // Registered straight away, so a plan naming the same étagère twice
                // fills the one draft rather than making a second.
                sectionByNameKey[key] = destination
            }

            changes.append(contentsOf: moves)
        }

        self.changes = changes
    }

    /// Whether the proposal has anything to add. A device that produced nothing, and a
    /// proposal that only re-files what is already filed, are both empty — and both
    /// must leave the stack exactly as it was.
    var isEmpty: Bool { changes.isEmpty }
}
