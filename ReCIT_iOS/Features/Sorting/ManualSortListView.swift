//
//  ManualSortListView.swift
//  ReCIT_iOS
//
//  The surface once the snapshot is frozen: one section per étagère, then the pile,
//  then the buttons.
//
//  Everything it draws comes out of `SortProjection`, which is a pure function of the
//  snapshot and the change stack — so the screen has no state of its own to keep in
//  step with anything, and the rule that every book sits in exactly one section is
//  enforced before this view ever sees the data. A drop appends one change and the
//  sections are recomputed; nothing here moves a book by hand, which is why a book
//  cannot be in two places even for a frame.
//
//  It owns exactly one piece of state: which drop destination the finger is over. That
//  cannot live in a section, because only one section may be highlighted at a time and
//  no section can see the others. The apply, its marks and its report all belong to the
//  session, which outlives this view — so leaving mid-run takes nothing away.
//
//  The buttons sit at the foot of the list rather than in a pinned bar. The design
//  proposes a pinned bar; the list already stacks a tab bar under it, and two bars is
//  166 pt of chrome on a screen whose whole point is showing books. Kept in the list —
//  and revisited if the sections ever grow long enough that the buttons become hard to
//  reach.
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

    @State private var targeted: ManualSortDropTarget?

    var body: some View {
        // Both derivations read once per render rather than once per section: they are
        // pure functions of the same two values, so reading them repeatedly would only
        // cost walks, but it is also how a list ends up rendering two different
        // reductions in one frame.
        let projection: SortProjection = session.projection
        let plan: SortWritePlan = session.writePlan
        // Derived here rather than held, which is what keeps the proposal button live:
        // the availability behind it reads an observable `SystemLanguageModel`, so a
        // user who switches Apple Intelligence on and comes back finds the button
        // enabled with no relaunch. Same lever as `ProfileView`.
        let entryPoint: AutoSortEntryPoint = .init(availability: autoSortModel.availability)

        return List {
            ForEach(projection.sections) { section in
                ManualSortSectionView(
                    section: section,
                    status: plan.status(of: section.id),
                    isDropTarget: targeted?.section == section.id,
                    mark: session.applyOutcome(of: section.id),
                    onDrop: { drop($0, onto: section.id) },
                    onTargeted: setTargeted
                )
            }

            // The account of the last run, once there has been one. It stays after the
            // run settles — it is what a user who left mid-apply comes back for — and
            // is replaced when the next run starts.
            if let progress = session.applyProgress, progress.isFinished {
                Section {
                    ManualSortApplyReport(progress: progress)
                }
            }

            // Silent while nothing has been done — an empty stack has nothing to
            // recap. Once something has, the recap speaks even if it coalesces to
            // nothing, because the buttons are still offering to save and discard.
            // After a run that stopped partway it describes exactly what is left,
            // which is the same thing pressing the button again would send.
            if plan.hasPendingChanges {
                Section {
                    ManualSortRecapView(plan: plan)
                }
            }

            Section {
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
            }
            .listRowBackground(DesignSystem.Color.clear.color)
        }
        .applyListBackground()
    }

    /// Asks the on-device model for a rangement. What comes back is appended to the same
    /// stack a drag appends to, so it is adjustable by dragging and « Annuler » discards
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

    /// Fires the run and returns. The writes are owned by the session, so this screen
    /// can go away without stopping them or losing the ledger of what landed.
    private func apply() {
        session.apply(
            shelfModel: shelfModel,
            errorReporter: errorReporter,
            modelContext: modelContext
        )
    }

    /// One drop, one change. The origin travels with the book, so the stack records
    /// both ends of the move without asking the projection where the book was.
    private func drop(
        _ transfers: [SortBookTransfer],
        onto section: SortSection.ID
    ) -> Bool {
        targeted = nil
        for transfer in transfers {
            session.moveBook(transfer.bookId, from: transfer.origin, to: section)
        }
        return transfers.isEmpty == false
    }

    /// A destination only gives up the highlight if it is still the one holding it.
    /// Crossing from one row to the next fires the arrival and the departure in an
    /// order nobody promises, and clearing unconditionally would blank the band the
    /// finger is over half the time.
    private func setTargeted(_ isTargeted: Bool, _ target: ManualSortDropTarget) {
        if isTargeted {
            targeted = target
        } else if targeted == target {
            targeted = nil
        }
    }
}
