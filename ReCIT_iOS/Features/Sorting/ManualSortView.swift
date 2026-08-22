//
//  ManualSortView.swift
//  ReCIT_iOS
//
//  The sorting surface: the whole library laid out as it will be filed. Every étagère is a
//  card on a three-column grid that scrolls; the books on no étagère are a carousel in a
//  panel anchored to the foot of the screen, with the recap and the three controls under it.
//
//  **Why the panel does not scroll** is the decision the screen turns on (PRD 0009): the
//  source of a drag stays under the thumb while the destinations move under the finger,
//  taking a book back *off* an étagère always has a target on screen, and « Appliquer » is
//  never several screens below the work. The panel is content, not chrome, so the argument
//  PRD 0008 used against a pinned bar does not apply to it.
//
//  On arrival it syncs shelves and inventory behind a progress indicator — a user about to
//  rearrange their library must not be doing it against a stale one — and then freezes what
//  it read. Why the freeze, and why it is a deliberate departure from ADR 0001, is written
//  where it happens: `SortSessionModel.freeze`.
//
//  **It reads the projection once.** Both derivations are recomputed on every read by design,
//  so a card that read the session in its own body would pay a walk over the whole library
//  per card per animation frame. They are read here, and value types go down.
//
//  Nothing is written until « Appliquer ». The session holding the snapshot and the stack is
//  app-scoped, so a draft survives leaving the screen, and so do the writes and the ledger of
//  what landed.
//
//  See PRD 0008 and PRD 0009.
//

import SwiftUI
import SwiftData

struct ManualSortView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext

    @Environment(SortSessionModel.self) private var session

    @Binding var path: NavigationPath

    /// Presents the create form. The one piece of state this screen owns — the session holds
    /// everything else, and a sheet that is up is not something a sorting session should
    /// survive being left for.
    @State private var isCreatingShelf: Bool = false

    /// The width every measurement on the screen is derived from. Reported rather than read
    /// through a `GeometryReader`, which would take over the layout it is only measuring.
    @State private var containerWidth: CGFloat = 0

    /// The one-off sentence the footer owes the user, if any. Held by the screen rather than
    /// the session: it is about a button that was pressed here, and it must not outlive the
    /// next change to the stack.
    @State private var notice: SortNotice?

    var body: some View {
        // Read once per render. Both are pure functions of the same two values, so reading
        // them per card would only cost walks — but it is also how one frame ends up
        // rendering two different reductions.
        let projection: SortProjection = session.projection
        let plan: SortWritePlan = session.writePlan
        let metrics: SortGridMetrics = .init(containerWidth: containerWidth)

        return VStack(spacing: .zero) {
            if session.phase == .syncing || containerWidth == 0 {
                SyncingPlaceholderView(message: "manual_sort.syncing")
            } else {
                SortShelvesGridView(
                    sections: projection.sections.filter { $0.isUnshelved == false },
                    plan: plan,
                    metrics: metrics,
                    isActive: session.isBusy == false,
                    isApplying: session.isApplying,
                    outcome: session.applyOutcome(of:),
                    onDrop: { bookId, section in
                        file(bookId, into: section.id, within: projection)
                    }
                )
            }

            SortUnshelvedPanelView(
                books: projection.unshelved.books,
                metrics: metrics,
                isLoading: session.phase == .syncing,
                isActive: session.isBusy == false,
                isApplying: session.isApplying,
                onDrop: { bookId in
                    file(bookId, into: .unshelved, within: projection)
                },
                footer: .init(plan: plan, progress: session.applyProgress, notice: notice),
                actions: actions
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.backgroundSecondary.color)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            containerWidth = width
        }
        .navigationTitle("manual_sort.title")
        .navigationBarTitleDisplayMode(.inline)
        // Declared here rather than in the stack's owner: the destination is a section of
        // *this* screen's session, and `SortSection.ID` is already `Hashable`, so nothing has
        // to be encoded into the app-wide navigation enum for it.
        .navigationDestination(for: SortSection.ID.self) { sectionId in
            SortShelfDetailView(sectionId: sectionId)
        }
        .toolbar {
            // Absent until the snapshot exists, exactly as the design has it: there is
            // nothing to name an étagère against while the library is still being read, so
            // the naming rule would have nothing to refuse.
            //
            // A run in flight only *disables* it, on the action bar's reasoning: what the
            // button offers is still true, it is simply not offered while the writes settle.
            if session.phase == .ready {
                ToolbarItem(placement: .primaryAction) {
                    Button("manual_sort.create_shelf", systemImage: "plus") {
                        isCreatingShelf = true
                    }
                    .disabled(session.isBusy)
                }
            }
        }
        // The form writes nothing. It hands back a name, the name becomes a draft on the
        // stack, and the draft is a section that accepts drops straight away — which is what
        // makes "create it, fill it, then save" one movement (PRD 0008).
        .sheet(isPresented: $isCreatingShelf) {
            ShelfFormView(
                draft: .init(
                    nameRule: session.draftNameRule,
                    onCreate: session.createShelf(named:)
                )
            )
        }
        .task {
            guard let user = userModel.myUser else { return }
            await session.load(
                user: user,
                shelfModel: shelfModel,
                inventoryModel: inventoryModel,
                errorReporter: errorReporter,
                modelContext: modelContext
            )
        }
    }

    /// The three controls, with the availability read fresh in this body so that switching
    /// Apple Intelligence on and coming back finds the proposal live with no relaunch.
    private var actions: SortActions {
        .init(
            hasPendingChanges: session.hasPendingChanges,
            entryPoint: .init(availability: autoSortModel.availability),
            isProposing: session.isProposing,
            isApplying: session.isApplying,
            onDiscard: discard,
            onApply: apply,
            onPropose: propose
        )
    }

    /// One drop: the book leaves wherever the projection says it is for the section it was
    /// let go on.
    ///
    /// **The origin is resolved here, not carried in the payload.** The projection is the
    /// only thing that knows where a book sits, and a payload that named its origin could
    /// name one the book had since left — which is what the first attempt at this gesture
    /// got wrong (PRD 0008, superseded).
    ///
    /// A drop back onto the section the book already sits in is taken and records nothing:
    /// `SortChange.move` returns `nil` for it, so the stack does not grow, the discard
    /// control stays inert, and there is no bounce and no haptic. The silence is the honest
    /// answer — nothing happened.
    private func file(
        _ bookId: String,
        into destination: SortSection.ID,
        within projection: SortProjection
    ) -> Bool {
        guard session.isBusy == false else { return false }
        guard let origin = projection.sections.first(where: { section in
            section.books.contains { $0.id == bookId }
        })?.id else { return false }

        notice = nil
        guard origin != destination else { return true }

        session.moveBook(bookId, from: origin, to: destination)
        Haptics.Impact.light.play()
        return true
    }

    private func discard() {
        notice = nil
        session.discardChanges()
    }

    /// Fires the run and returns. The writes are owned by the session, so this screen can go
    /// away without stopping them or losing the ledger of what landed.
    private func apply() {
        notice = nil
        session.apply(
            shelfModel: shelfModel,
            errorReporter: errorReporter,
            modelContext: modelContext
        )
    }

    /// Asks the on-device model for a rangement. What comes back is appended to the same stack
    /// a drop appends to, so it is adjustable by dragging and the discard control throws it
    /// away like anything else (PRD 0008).
    ///
    /// The task is not tied to this view's lifetime: a proposal is a wait the user triggered,
    /// and leaving the screen mid-run should find the changes on the stack on their return,
    /// exactly as leaving mid-apply finds the ledger.
    private func propose() {
        guard let user = userModel.myUser else { return }

        notice = nil
        Task {
            let countBefore: Int = session.changes.count
            await session.proposeArrangement(
                user: user,
                autoSortModel: autoSortModel,
                errorReporter: errorReporter,
                modelContext: modelContext
            )
            // Said here rather than left to the error reporter: its SnackBar is owned by
            // `MainTabView`, which does not draw above this screen's cover, and from the far
            // side of a wait the user triggered a screen that does not change is
            // indistinguishable from a button that does not work.
            if session.changes.count == countBefore {
                notice = .nothingToPropose
            }
        }
    }
}
