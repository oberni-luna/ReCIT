//
//  EditionDuplicatesReview.swift
//  ReCIT_iOS
//
//  « Doublon 1 sur 2 » — the duplicates of « Éditions », one pair at a time: which edition to
//  keep, what differs between the two, and the two answers at the foot of the screen.
//  « Suivant » leaves the pair for later. When no pair is left the screen goes back to the list,
//  where one SnackBar says what was merged and what was reported.
//  `C2 · Doublon probable · 1 sur 2` (`770:5186`) in the Figma file.
//
//  The pairs are found again from the store at every render, not handed in: once a pair is
//  decided the editions change, and the next pair is the detection's answer about what remains.
//
//  See PRD 0028.
//

import LBSnackBar
import SwiftUI
import SwiftData

struct EditionDuplicatesReview: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(EditionDuplicatesModel.self) private var duplicatesModel
    @Environment(AppErrorReporter.self) private var errorReporter

    @Query private var works: [Work]

    /// The pairs « Suivant » has put aside, by id.
    @State private var skipped: [String] = []
    /// How many pairs were answered — merged, reported or declared different.
    @State private var decided: Int = 0
    /// The edition the reader chose to keep, by pair id. The proposal otherwise.
    @State private var keptUris: [String: String] = [:]
    @State private var copyCounts: [String: Int] = [:]
    /// A merge is on its way: nothing else is sent until inventaire.io has answered.
    @State private var isMerging: Bool = false
    @State private var summary: DuplicatesReviewSummary = .init()

    init(workUri: String) {
        _works = Query(filter: #Predicate<Work> { $0.uri == workUri })
    }

    private var work: Work? {
        works.first
    }

    private var remaining: [EditionDuplicatePair] {
        guard let work else { return [] }
        return EditionDuplicateDetector.detect(work.editions.map(EditionFacts.init)).pairs
            .filter { skipped.contains($0.id) == false }
    }

    var body: some View {
        let remaining: [EditionDuplicatePair] = remaining
        let position: Int = decided + skipped.count + 1
        let total: Int = decided + skipped.count + remaining.count

        Group {
            if let pair = remaining.first, let work {
                EditionDuplicatePairForm(
                    pair: pair,
                    editions: work.editions,
                    keptUri: keptUri(in: pair),
                    copyCounts: copyCounts,
                    onKeep: { uri in keptUris[pair.id] = uri }
                )
                .task(id: pair.id) {
                    await loadCopyCounts(of: pair)
                }
            }
        }
        .navigationTitle("duplicates.review.title \(position) \(total)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("duplicates.review.next") {
                    if let pair = remaining.first {
                        skipped.append(pair.id)
                    }
                }
                .accessibilityIdentifier("e2e.duplicates.next")
            }
        }
        .safeAreaInset(edge: .bottom) {
            FormActionBar {
                VStack(spacing: .xSmall) {
                    AsyncButton(
                        action: { await merge(remaining.first) },
                        actionOptions: [.disableButton, .showProgressView],
                        label: {
                            Text("duplicates.review.merge")
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.primary())
                    .disabled(remaining.isEmpty || isMerging)
                    .accessibilityIdentifier("e2e.duplicates.merge")

                    Button {
                        guard let pair = remaining.first else { return }
                        duplicatesModel.markNotTheSame(pair, modelContext: modelContext)
                        decided += 1
                    } label: {
                        Text("duplicates.review.not_the_same")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary())
                    .disabled(remaining.isEmpty || isMerging)
                    .accessibilityIdentifier("e2e.duplicates.notTheSame")
                }
            }
        }
        .navigationBarBackButtonHidden(isMerging)
        .onChange(of: remaining.first?.id, initial: true) { _, id in
            if id == nil {
                dismiss()
            }
        }
        .onDisappear {
            if let message = summary.message {
                snackBar.show {
                    SnackBarView(title: message, onDismiss: nil)
                }
            }
        }
    }

    /// Sends the merge of `pair` and waits for inventaire.io. The store changes only once it has
    /// answered — see `EditionDuplicatesModel.merge`. A refusal is said in the SnackBar and leaves
    /// the pair where it is.
    private func merge(_ pair: EditionDuplicatePair?) async {
        guard let pair, let work, isMerging == false else { return }
        let keptUri: String = keptUri(in: pair)
        let kept: EditionFacts = pair.first.uri == keptUri ? pair.first : pair.second

        isMerging = true
        defer { isMerging = false }
        do {
            let outcome: MergeOutcome = try await duplicatesModel.merge(
                pair,
                keeping: kept,
                work: work,
                modelContext: modelContext
            )
            summary.record(outcome)
            decided += 1
        } catch {
            errorReporter.report(error)
        }
    }

    private func keptUri(in pair: EditionDuplicatePair) -> String {
        keptUris[pair.id] ?? MergeChoice.proposedKeep(in: pair, copyCounts: copyCounts).uri
    }

    private func loadCopyCounts(of pair: EditionDuplicatePair) async {
        for uri in [pair.first.uri, pair.second.uri] where copyCounts[uri] == nil {
            if let count = await duplicatesModel.copyCount(uri: uri) {
                copyCounts[uri] = count
            }
        }
    }
}
