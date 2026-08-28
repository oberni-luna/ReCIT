//
//  SortProposingView.swift
//  ReCIT_iOS
//
//  The wait between « Rangement automatique » on the bilan and the sorting surface arriving
//  with a proposal on it.
//
//  A screen of its own, which PRD 0009's issue 0052 originally forbade — no screen was to come
//  between the bilan and the surface — and that rule was withdrawn for this one case. The
//  model's run is the only genuinely slow moment in the flow, and the two alternatives are
//  worse: a veil over the bilan holds a screen the user has finished reading, and a surface
//  that arrives empty and fills itself in a second later reads as a bug the first time the
//  proposal is slow.
//
//  It **replaces itself** with the surface rather than being pushed under it, which is what
//  keeps 0052's other rule intact: the surface still has no back chevron to the bilan and still
//  leaves through its explicit close. Backing out of *this* screen is allowed and means "never
//  mind" — nothing has been written, and a proposal is only a stack of pending changes anyway.
//
//  It owns the two steps in order — opening the session, then asking the model — because the
//  proposal resolves its names against the session's sections, and asking before the freeze
//  would resolve them against nothing.
//

import SwiftUI
import SwiftData

struct SortProposingView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(SortSessionModel.self) private var session
    @Environment(\.modelContext) private var modelContext

    /// Called once the model has answered, whatever it answered. The caller replaces this
    /// screen with the surface; `proposed` says whether anything landed on the stack, so the
    /// surface can say so rather than looking unchanged for no stated reason.
    let onReady: (_ proposed: Bool) -> Void

    var body: some View {
        VStack(spacing: .medium) {
            ProgressView()
                .controlSize(.large)

            Text("manual_sort.proposing")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.all, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .navigationBarBackButtonHidden(false)
        .task(propose)
    }

    /// Opens the session, then asks the model, then hands back — in that order and once.
    ///
    /// A failure is not surfaced here: `proposeArrangement` already reports it, and this screen
    /// is on its way out either way. What the caller is told is whether the stack grew, which is
    /// the only thing the surface needs in order to explain itself.
    @Sendable
    private func propose() async {
        guard let user = userModel.myUser else {
            onReady(false)
            return
        }

        await session.load(
            user: user,
            shelfModel: shelfModel,
            inventoryModel: inventoryModel,
            errorReporter: errorReporter,
            modelContext: modelContext
        )

        let countBefore: Int = session.changes.count
        await session.proposeArrangement(
            user: user,
            autoSortModel: autoSortModel,
            errorReporter: errorReporter,
            modelContext: modelContext
        )

        onReady(session.changes.count > countBefore)
    }
}
