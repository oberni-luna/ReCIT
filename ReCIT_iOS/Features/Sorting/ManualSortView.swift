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
//  This slice is read-only. The handles are drawn but inert, the stack is always
//  empty, and therefore the primary button is inert and the third one reads
//  « Terminer ». Dragging (0038), the pills and recap (0039), the apply (0040), the
//  inline create form (0041) and the AI proposal (0042) land on this same screen.
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

    @Binding var path: NavigationPath

    @State private var session: SortSessionModel = .init()

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

    /// « Terminer » leaves the screen. Nothing to undo — this slice writes nothing.
    private func close() {
        if path.isEmpty == false {
            path.removeLast()
        }
    }
}
