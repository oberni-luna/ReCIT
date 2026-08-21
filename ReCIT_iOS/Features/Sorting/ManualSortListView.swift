//
//  ManualSortListView.swift
//  ReCIT_iOS
//
//  The surface once the snapshot is frozen: every étagère with its books, then the pile,
//  then the buttons.
//
//  Everything it draws comes out of `SortProjection`, which is a pure function of the
//  snapshot and the change stack — so the screen has no state of its own to keep in step
//  with anything, and the rule that every book sits in exactly one section is enforced
//  before this view ever sees the data. A move appends one change and the rows are
//  recomputed; nothing here moves a book by hand, which is why a book cannot be in two
//  places even for a frame.
//
//  **The gesture is the list's own.** The rows are flattened into a single `ForEach`
//  (`ManualSortRows`) and the list is held in edit mode, so reordering is SwiftUI's
//  native reorder: the system's grip, the system's lift, the system's animation, and a
//  drop that always lands. Crossing étagères works because there is only one `ForEach` to
//  cross — edit-mode reorder never leaves the one it started in. The first attempt at this
//  screen used `draggable`/`dropDestination` with a typed transfer, and the drag simply
//  did not take on device.
//
//  Edit mode is pinned active rather than toggled: every row carries a handle in the
//  design, there is nothing on this screen to select, and a mode the user has to find
//  first would put a tap between them and the only gesture the screen is for.
//
//  The buttons sit at the foot of the list rather than in a pinned bar. The design
//  proposes a pinned bar; the list already stacks a tab bar under it, and two bars is
//  166 pt of chrome on a screen whose whole point is showing books.
//
//  See PRD 0008.
//

import SwiftUI
import SwiftData

struct ManualSortListView: View {
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(UserModel.self) private var userModel
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext

    let session: SortSessionModel
    let onFinish: () -> Void

    var body: some View {
        // Read once per render rather than once per row: they are pure functions of the
        // same two values, so reading them repeatedly would only cost walks — but it is
        // also how a list ends up rendering two different reductions in one frame.
        let projection: SortProjection = session.projection
        let plan: SortWritePlan = session.writePlan
        let rows: ManualSortRows = .init(sections: projection.sections)
        // Derived here rather than held, which is what keeps the proposal button live:
        // the availability behind it reads an observable `SystemLanguageModel`, so a user
        // who switches Apple Intelligence on and comes back finds the button enabled with
        // no relaunch. Same lever as `ProfileView`.
        let entryPoint: AutoSortEntryPoint = .init(availability: autoSortModel.availability)

        return List {
            ForEach(rows.rows) { row in
                view(for: row, plan: plan)
                    .moveDisabled(row.isMovable == false)
            }
            .onMove { source, destination in
                move(source, to: destination, in: rows)
            }

            // The account of the last run, once there has been one. It stays after the run
            // settles — it is what a user who left mid-apply comes back for — and is
            // replaced when the next run starts.
            //
            // The recap is *not* drawn beside it: while a finished run is on screen the
            // report already says what happened, and the recap saying the same thing in
            // the present tense read as the screen contradicting itself.
            if let progress = session.applyProgress, progress.isFinished {
                ManualSortApplyReport(progress: progress)
                    .manualSortCardRow(isTop: true, isBottom: true, spacedAbove: true)
                    .moveDisabled(true)
            } else if plan.hasPendingChanges {
                // Silent while nothing has been done — an empty stack has nothing to
                // recap. Once something has, the recap speaks even if it coalesces to
                // nothing, because the buttons are still offering to save and discard.
                ManualSortRecapView(plan: plan)
                    .manualSortCardRow(isTop: true, isBottom: true, spacedAbove: true)
                    .moveDisabled(true)
            }

            ManualSortActionBar(
                hasPendingChanges: session.hasPendingChanges,
                entryPoint: entryPoint,
                isProposing: session.isProposing,
                isApplying: session.isApplying,
                onPropose: propose,
                onApply: apply,
                onDiscard: session.discardChanges,
                onFinish: onFinish
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(DesignSystem.Color.clear.color)
            .listRowSeparator(.hidden)
            .moveDisabled(true)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .applyListBackground()
    }

    @ViewBuilder
    private func view(for row: ManualSortRow, plan: SortWritePlan) -> some View {
        switch row.content {
        case .header(let section):
            ManualSortSectionHeader(
                section: section,
                status: plan.status(of: section.id),
                mark: session.applyOutcome(of: section.id)
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(DesignSystem.Color.clear.color)
            .listRowSeparator(.hidden)

        case .book(let book):
            SortBookRow(book: book)
                .manualSortCardRow(isTop: row.isCardTop, isBottom: row.isCardBottom)

        case .empty:
            ManualSortEmptySectionRow(isUnshelved: row.section == .unshelved)
                .manualSortCardRow(isTop: row.isCardTop, isBottom: row.isCardBottom)
        }
    }

    /// One move, one change. The origin comes off the row that was picked up and the
    /// destination off the index it was let go at, so the stack records both ends without
    /// asking the projection where the book was.
    ///
    /// A move that resolves to the section the book already sits in pushes nothing —
    /// `SortChange.move` returns `nil` for it — so nudging a row inside its own étagère
    /// costs the stack nothing, which is the honest outcome when order within an étagère
    /// is not part of the state.
    ///
    /// **The permutation is handed over, not re-derived.** Edit-mode reorder is positional:
    /// it animates the row into the exact slot the finger chose. Any order the projection
    /// invented — snapshot order, arrival order — was a different arrangement, and SwiftUI
    /// animated the difference on top of the drop, which is what left a dropped row sitting
    /// over the row it landed on for half a second. So the same `move(fromOffsets:toOffset:)`
    /// the list just performed is applied here and passed down as the display order. Nothing
    /// is derived twice, so there is no second diff to animate.
    ///
    /// Do **not** reach for a transaction with `disablesAnimations` instead. It stops the
    /// list reconciling after its own reorder: the cell stays where UIKit moved it, the
    /// change is never pushed, and the headers go on reporting the old counts.
    private func move(_ source: IndexSet, to destination: Int, in rows: ManualSortRows) {
        guard let target = rows.section(forInsertionAt: destination) else { return }

        var permuted: [ManualSortRow] = rows.rows
        permuted.move(fromOffsets: source, toOffset: destination)
        let order: [String] = permuted.compactMap { row in
            if case .book(let book) = row.content { book.id } else { nil }
        }

        for index in source {
            guard let book = rows.book(at: index) else { continue }
            session.moveBook(book.id, from: book.origin, to: target, order: order)
        }
    }

    /// Asks the on-device model for a rangement. What comes back is appended to the same
    /// stack a move appends to, so it is adjustable by dragging and « Annuler » discards
    /// it like anything else (PRD 0008).
    ///
    /// The task is not tied to this view's lifetime: a proposal is a wait the user
    /// triggered, and leaving the screen mid-run should find the changes on the stack on
    /// their return, exactly as leaving mid-apply finds the ledger.
    private func propose() {
        guard let user = userModel.myUser else { return }

        Task {
            await session.proposeArrangement(
                user: user,
                autoSortModel: autoSortModel,
                errorReporter: errorReporter,
                modelContext: modelContext
            )
        }
    }

    /// Fires the run and returns. The writes are owned by the session, so this screen can
    /// go away without stopping them or losing the ledger of what landed.
    private func apply() {
        session.apply(
            shelfModel: shelfModel,
            errorReporter: errorReporter,
            modelContext: modelContext
        )
    }
}
