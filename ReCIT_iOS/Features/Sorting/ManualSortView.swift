//
//  ManualSortView.swift
//  ReCIT_iOS
//
//  The sorting surface: the whole library laid out as it is filed. Every étagère is a
//  section with the books it holds, and last comes « À ranger », the books that are on
//  no étagère at all.
//
//  Reached from the étagères screen. On arrival it syncs shelves and inventory against
//  the server behind a progress indicator — a user is about to rearrange their library
//  and must not be doing it against a stale one — and then freezes what it read. Why
//  the freeze, and why it is a deliberate departure from ADR 0001, is written where it
//  happens: `SortSessionModel.freeze`.
//
//  Books are filed by dragging them from one section onto another; nothing is written.
//  The session that holds the snapshot and the stack is **app-scoped**, so a draft
//  survives leaving the screen — and, from slice 0040, so will the writes and the
//  ledger of what landed. The pills and recap (0039), the apply (0040) and the create
//  form behind the « + » (0041) are all on this screen; the AI proposal (0042) lands
//  here too.
//
//  It stands *alongside* the auto-sort review screen, which keeps working untouched
//  until slice 0043 dismantles it.
//
//  See PRD 0008.
//

import SwiftUI
import SwiftData

struct ManualSortView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext

    @Environment(SortSessionModel.self) private var session

    @Binding var path: NavigationPath

    /// Presents the create form. The one piece of state this screen owns — the session
    /// holds everything else, and a sheet that is up is not something a sorting session
    /// should survive being left for.
    @State private var isCreatingShelf: Bool = false

    var body: some View {
        Group {
            switch session.phase {
            case .syncing:
                SyncingPlaceholderView(message: "manual_sort.syncing")
            case .ready:
                ManualSortListView(
                    session: session,
                    onFinish: close
                )
            }
        }
        .navigationTitle("manual_sort.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Absent until the snapshot exists, exactly as the design has it: there is
            // nothing to name an étagère against while the library is still being read,
            // so the naming rule would have nothing to refuse.
            //
            // A run in flight only *disables* it, on the action bar's reasoning: what
            // the button offers is still true, it is simply not offered while the writes
            // settle. The stack must not grow under a plan that was reduced from it —
            // nor under a proposal that resolved its names against the sections as they
            // stood, which is why a run of either kind stands it down.
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
        // stack, and the draft is a section that accepts drops straight away — which is
        // what makes "create it, fill it, then save" one movement (PRD 0008).
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

    /// « Terminer » leaves the screen. Only reachable with an empty stack: while there
    /// is something to discard the same button says « Annuler » and discards it.
    private func close() {
        if path.isEmpty == false {
            path.removeLast()
        }
    }
}
