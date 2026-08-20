//
//  AutoSortPlanView.swift
//  ReCIT_iOS
//
//  The review. Each proposed étagère, how many books it would hold, and which
//  books — the last of these because a count alone cannot show a misclassification,
//  and spotting one before it happens is the point of reviewing at all.
//
//  Approving turns this same list into the progress list: each étagère's row keeps its
//  place and gains a mark that fills once both its creation and its membership write
//  have landed. No separate progress screen, which is what makes a partial failure
//  explain itself — the marks *are* the account of what exists, and nothing is rolled
//  back. See `AutoSortShelfMark` and `AutoSortApplyReport`.
//
//  Reached from the profile/settings screen. The empty-shelf entry point and the
//  differentiated treatment of the three unavailability reasons are issue 0025;
//  what is here is the plain "not available" wall.
//
//  See PRD 0006.
//

import SwiftUI
import SwiftData

struct AutoSortPlanView: View {
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    @Binding var path: NavigationPath

    var body: some View {
        Group {
            if autoSortModel.availability.isAvailable {
                content
            } else {
                unavailableView
            }
        }
        .navigationTitle("Ranger mes livres")
        .navigationBarTitleDisplayMode(.inline)
        // Gone while the run is writing: leaving mid-apply would clear the ledger the
        // user needs in order to know what landed, and the writes would carry on
        // regardless since the model outlives this screen.
        .toolbar {
            if autoSortModel.plan != nil, !autoSortModel.isRunning {
                ToolbarItem(placement: .primaryAction) {
                    Button(autoSortModel.phase == .applied ? "Terminer" : "Annuler", action: cancel)
                }
            }
        }
        // Generated on arrival rather than behind a button: the user already asked
        // for this by navigating here, and a second tap would only add a wait they
        // have to trigger themselves.
        .task {
            guard autoSortModel.availability.isAvailable,
                  autoSortModel.plan == nil,
                  !autoSortModel.isRunning,
                  let user = userModel.myUser else { return }
            await autoSortModel.generatePlan(forUser: user, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch autoSortModel.phase {
        case .idle, .analysingLibrary, .designingShelves, .sortingGenres:
            runningView
        case .failed:
            failedView
        case .ready, .applying, .applied:
            if let plan = autoSortModel.plan {
                planList(plan)
            } else {
                failedView
            }
        }
    }

    /// One indeterminate wait with changing copy rather than a progress bar per
    /// phase: the three phases are of wildly different lengths and a bar that
    /// restarts three times reads as three failures.
    @ViewBuilder
    private var runningView: some View {
        VStack(spacing: .medium) {
            ProgressView()
            Text(autoSortModel.statusText)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, .large)
    }

    @ViewBuilder
    private var failedView: some View {
        VStack(spacing: .medium) {
            Text("Le rangement n'a pas pu être proposé.")
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task {
                    guard let user = userModel.myUser else { return }
                    await autoSortModel.generatePlan(forUser: user, modelContext: modelContext)
                }
            }
            .buttonStyle(.primary())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, .large)
    }

    @ViewBuilder
    private var unavailableView: some View {
        Text("Le rangement automatique n'est pas disponible sur cet appareil.")
            .textStyle(.content300)
            .foregroundStyle(.foregroundSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.all, .large)
    }

    @ViewBuilder
    private func planList(_ plan: AutoSortPlan) -> some View {
        List {
            if plan.isEmpty {
                Section {
                    Text("Aucun genre n'a pu être identifié dans vos livres non rangés. Ils restent où ils sont.")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            ForEach(plan.shelves) { shelf in
                Section {
                    ForEach(shelf.books) { book in
                        AutoSortBookRow(book: book)
                    }
                } header: {
                    // Name and count together in the header: the count is the thing
                    // the user judges the split on, and putting it anywhere else
                    // makes them scroll to find it. The mark leads, so the list reads
                    // as a checklist the moment the run starts ticking it off.
                    HStack {
                        AutoSortShelfMark(outcome: outcome(for: shelf))
                        Text(shelf.name)
                            .textStyle(.action300)
                            .foregroundStyle(.foregroundDefault)
                        Spacer()
                        Text("\(shelf.bookCount) livre\(shelf.bookCount > 1 ? "s" : "")")
                            .textStyle(.action200)
                            .foregroundStyle(.foregroundSecondary)
                    }
                }
            }

            // The books nobody could classify are shown as a count, not a list:
            // they are the honest residue of patchy genre data, and a long list of
            // books that are *not* being touched would drown the proposal.
            if !plan.leftUnshelved.isEmpty {
                Section {
                    Text("\(plan.leftUnshelved.count) livre\(plan.leftUnshelved.count > 1 ? "s" : "") restera\(plan.leftUnshelved.count > 1 ? "ont" : "") sans étagère, faute de genre connu.")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            // Said out loud rather than logged only: a plan built from a partly
            // hallucinated mapping is still a valid plan, and the reviewer is the
            // one person who can tell whether what survived is worth keeping.
            if !autoSortModel.rejections.isEmpty {
                Section {
                    Text("\(autoSortModel.rejections.count) proposition\(autoSortModel.rejections.count > 1 ? "s" : "") a été écartée car elle ne correspondait à aucune étagère proposée.")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            actionsSection
        }
        .applyListBackground()
    }

    /// The foot of the list, and the only part of it that changes shape across the run:
    /// approve, then wait, then read what happened. Kept in the list rather than pinned
    /// as a bar so the marks above it stay the primary account of progress.
    @ViewBuilder
    private var actionsSection: some View {
        switch autoSortModel.phase {
        case .applying:
            Section {
                HStack(spacing: .sMedium) {
                    ProgressView()
                    Text(autoSortModel.statusText)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            } footer: {
                Text("Chaque étagère est créée puis remplie. Ne quittez pas l'écran pour suivre la progression.")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }

        case .applied:
            Section {
                if let progress = autoSortModel.applyProgress {
                    AutoSortApplyReport(progress: progress)
                }
                // Offered only when something is actually left to do. A completed run
                // has nothing to pick up, and a button that would produce an empty plan
                // is worse than no button.
                if autoSortModel.applyProgress?.result != .allLanded {
                    Button("Relancer le rangement", action: regenerate)
                        .buttonStyle(.primary())
                }
            }

        default:
            Section {
                Button("Créer ces étagères", action: apply)
                    .buttonStyle(.primary())
                    .disabled(!autoSortModel.canApply)
                Button("Annuler", action: cancel)
            } footer: {
                Text("Rien n'a encore été créé : ce rangement est une proposition. Vos livres déjà rangés ne seront pas touchés.")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }

    /// A shelf's mark before the run has started is simply "not created yet", which is
    /// what an absent ledger means.
    private func outcome(for shelf: AutoSortPlan.ProposedShelf) -> AutoSortApplyProgress.ShelfOutcome {
        autoSortModel.applyProgress?.outcome(for: shelf.name) ?? .pending
    }

    /// Approves the plan. The write is awaited inside the app-scoped model, so it
    /// survives this screen going away — but the marks do not, which is why the toolbar
    /// exit is withdrawn while it runs.
    private func apply() {
        Task {
            guard let user = userModel.myUser else { return }
            await autoSortModel.apply(forUser: user, modelContext: modelContext)
        }
    }

    /// Recovery after a partial failure: a *new* plan, not a re-apply of the old one.
    /// It picks up only the books still on no étagère, so the étagères that landed are
    /// not proposed again and nothing is created twice.
    private func regenerate() {
        Task {
            guard let user = userModel.myUser else { return }
            await autoSortModel.generatePlan(forUser: user, modelContext: modelContext)
        }
    }

    /// Discards the proposal and leaves. Nothing to undo — the run wrote nothing.
    private func cancel() {
        autoSortModel.cancel()
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
