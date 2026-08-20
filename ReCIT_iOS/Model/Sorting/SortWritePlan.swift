//
//  SortWritePlan.swift
//  ReCIT_iOS
//
//  Snapshot + change stack → what applying would do. The second of PRD 0008's two
//  derivations, and the one nobody looks at directly: it draws the pills, writes the
//  recap, and — from slice 0040 — is the write itself.
//
//  **One reduction, three readings.** `operations` is what gets sent, `status(of:)` is
//  what each étagère's pill says, `summary` is what the recap sentence is built from.
//  They are three views of a single pass, which is the whole argument for deriving
//  rather than tracking: a pill cannot claim an étagère changed while the write leaves
//  it alone, because both answers come out of the same walk. Two modules computing
//  "is this étagère modified" would agree on the day they were written and on no
//  other.
//
//  **The reduction is a diff of two projections** — the library as the snapshot holds
//  it, and the library as the stack leaves it. That is not a shortcut: the projection
//  owns the rule that a book sits in exactly one section, and a plan that partitioned
//  the books a second time by hand would eventually partition them differently from
//  the screen. Written this way the operations can only ever describe memberships the
//  user actually saw. The dependency runs one way only — the projection knows nothing
//  of this type (see PRD 0008).
//
//  Coalescing falls out of the diff rather than being a rule of its own: a book moved
//  three times has one origin and one destination, so it is one removal and one
//  addition; a book taken off an étagère and put back has the same origin and
//  destination, so it is nothing at all, and the pill goes out with it.
//
//  Two rules are stated here rather than left implicit:
//
//  - **A draft that ends up empty is not created.** It yields no operation, and the
//    recap names it as dropped rather than passing over it in silence — a shelf that
//    quietly fails to appear reads as a bug.
//  - **An étagère emptied by dragging is modified, never deleted.** A removal is a
//    removal; a drag does not delete a shelf behind the user's back (PRD 0008).
//
//  Pure by design — no store, no network, no SwiftUI. See PRD 0008.
//

import Foundation

struct SortWritePlan: Equatable, Sendable {

    /// Which side of the pending work one étagère is on — the pill, in model terms.
    ///
    /// **Absence carries the normal state**: an étagère that exists and is untouched
    /// shows nothing, so what is pending reads at a glance without counting anything.
    enum ShelfStatus: Equatable, Sendable {
        /// Exists on the server, and applying would not touch it. No pill.
        case untouched
        /// Does not exist on the server yet. « Nouvelle », tinted.
        ///
        /// A draft left empty is still `new` — it does not exist, which is exactly
        /// what the pill says — but it produces no operation, and the recap names it
        /// among the drafts that will be dropped. The pill states what the section
        /// *is*; the recap states what will *happen* to it.
        case new
        /// Exists on the server and its contents have changed. « Modifiée », secondary.
        case modified
    }

    /// One étagère's whole share of the write, in the order it has to be sent:
    /// create it if it is a draft, then take books off, then put books on.
    ///
    /// **Removals before additions**, so a book is never on two étagères even
    /// momentarily. A move between two étagères is therefore split across two of
    /// these — and if the removal lands and the addition does not, the book falls
    /// back into the unshelved pile, which is an honest intermediate state and never
    /// a lost book.
    ///
    /// Grouped this way here rather than at execution time because slice 0040 marks
    /// progress one étagère at a time: a plan it had to regroup would be a plan whose
    /// grouping could differ from the marks the user is reading.
    struct ShelfWrite: Identifiable, Equatable, Sendable {

        /// The étagère this group writes to — `.shelf` for one the server already
        /// holds, `.draft` for one that has to be created first.
        let section: SortSection.ID

        /// Its name: what a draft is created under, and what a mark or a failure
        /// report names it by.
        let name: String

        /// Whether the étagère has to be brought into existence before anything can
        /// be filed into it. True for exactly the drafts that ended up holding books.
        let createsShelf: Bool

        /// `InventoryItem._id`s to take off this étagère.
        let removals: [String]

        /// `InventoryItem._id`s to file onto it.
        let additions: [String]

        var id: SortSection.ID { section }
    }

    /// The counts the recap sentence is built from — and nothing else. Four numbers
    /// rather than a formatted string, because the sentence is copy and copy lives in
    /// the string catalogue with its plural rules.
    struct Summary: Equatable, Sendable {

        /// Drafts that will be created. Drafts left empty are not among them.
        let shelvesToCreate: Int

        /// Étagères that already exist and whose contents change.
        let shelvesModified: Int

        /// Books that end up on an étagère they were not on. A book dragged into the
        /// pile is not filed — it is counted by `booksLeftUnshelved` instead, which
        /// is the state the user asked about.
        let booksFiled: Int

        /// Books that will still be on no étagère once this is applied. The one count
        /// that describes the result rather than the work.
        let booksLeftUnshelved: Int

        /// Names of the drafts that end up empty and will therefore not be created.
        /// Named rather than counted: the user is about to lose a shelf they typed a
        /// name for, and « une étagère » would not tell them which.
        let droppedDrafts: [String]
    }

    /// What applying sends, one group per étagère, in the order the screen shows them
    /// — so the marks tick down the list rather than around it.
    let operations: [ShelfWrite]

    let summary: Summary

    /// Whether the user has done anything at all, as opposed to whether it amounts to
    /// anything. The two differ exactly when the stack coalesces to nothing, and the
    /// recap has to tell those apart: nothing done is silence, whereas work that
    /// cancels itself out has to be said out loud or it reads as a broken screen.
    let hasPendingChanges: Bool

    private let statuses: [SortSection.ID: ShelfStatus]

    init(
        snapshot: SortSnapshot,
        changes: [SortChange] = []
    ) {
        let before: SortProjection = .init(snapshot: snapshot)
        let after: SortProjection = .init(snapshot: snapshot, changes: changes)

        var booksBefore: [SortSection.ID: [String]] = [:]
        for section in before.sections {
            booksBefore[section.id] = section.books.map(\.id)
        }

        var operations: [ShelfWrite] = []
        var statuses: [SortSection.ID: ShelfStatus] = [:]
        var droppedDrafts: [String] = []

        // The pile is skipped: it is not an étagère and has no membership of its own.
        // A book dropped into it is a removal on the étagère it left, and nothing else.
        for section in after.sections where section.isUnshelved == false {
            let had: [String] = booksBefore[section.id] ?? []
            let has: [String] = section.books.map(\.id)
            let hadIds: Set<String> = .init(had)
            let hasIds: Set<String> = .init(has)

            // Snapshot order on both sides, so the same stack always produces the
            // same operations — a plan that reordered itself between two renders
            // would make the marks jump around during an apply.
            let removals: [String] = had.filter { hasIds.contains($0) == false }
            let additions: [String] = has.filter { hadIds.contains($0) == false }

            var isDraft: Bool = false
            if case .draft = section.id { isDraft = true }

            if isDraft {
                statuses[section.id] = .new

                guard has.isEmpty == false else {
                    if let name = section.name {
                        droppedDrafts.append(name)
                    }
                    continue
                }
            } else {
                let isTouched: Bool = removals.isEmpty == false || additions.isEmpty == false
                statuses[section.id] = isTouched ? .modified : .untouched

                guard isTouched else { continue }
            }

            operations.append(
                .init(
                    section: section.id,
                    name: section.name ?? "",
                    createsShelf: isDraft,
                    removals: removals,
                    additions: additions
                )
            )
        }

        self.operations = operations
        self.statuses = statuses
        hasPendingChanges = changes.isEmpty == false
        summary = .init(
            shelvesToCreate: operations.count(where: \.createsShelf),
            shelvesModified: operations.count { $0.createsShelf == false },
            booksFiled: operations.reduce(0) { $0 + $1.additions.count },
            booksLeftUnshelved: after.unshelved.books.count,
            droppedDrafts: droppedDrafts
        )
    }

    /// What one section's pill says. Unknown sections — and the pile, which never
    /// carries one — are untouched, which is the absence the design relies on.
    func status(of section: SortSection.ID) -> ShelfStatus {
        statuses[section] ?? .untouched
    }

    /// Whether applying would send anything. False both for an untouched library and
    /// for a stack that cancels itself out; `hasPendingChanges` separates the two.
    var hasWork: Bool { operations.isEmpty == false }
}
