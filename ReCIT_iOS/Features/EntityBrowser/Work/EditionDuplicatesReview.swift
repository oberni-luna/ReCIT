//
//  EditionDuplicatesReview.swift
//  ReCIT_iOS
//
//  « Doublon 1 sur 2 » — the duplicates of « Éditions », one pair at a time: which edition to
//  keep, what differs between the two, and the two answers at the foot of the screen.
//  « Suivant » leaves the pair for later. When no pair is left the screen goes back to the list.
//  `C2 · Doublon probable · 1 sur 2` (`770:5186`) in the Figma file.
//
//  The pairs are found again from the store at every render, not handed in: once a pair is
//  decided the editions change, and the next pair is the detection's answer about what remains.
//
//  See PRD 0028.
//

import SwiftUI
import SwiftData

struct EditionDuplicatesReview: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(EditionDuplicatesModel.self) private var duplicatesModel

    @Query private var works: [Work]

    /// The pairs « Suivant » has put aside, by id.
    @State private var skipped: [String] = []
    /// How many pairs were answered — merged, reported or declared different.
    @State private var decided: Int = 0
    /// The edition the reader chose to keep, by pair id. The proposal otherwise.
    @State private var keptUris: [String: String] = [:]
    @State private var copyCounts: [String: Int] = [:]

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
                    Button {
                    } label: {
                        Text("duplicates.review.merge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary())
                    .disabled(true)

                    Button {
                        guard let pair = remaining.first else { return }
                        duplicatesModel.markNotTheSame(pair, modelContext: modelContext)
                        decided += 1
                    } label: {
                        Text("duplicates.review.not_the_same")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary())
                    .disabled(remaining.isEmpty)
                    .accessibilityIdentifier("e2e.duplicates.notTheSame")
                }
            }
        }
        .onChange(of: remaining.first?.id, initial: true) { _, id in
            if id == nil {
                dismiss()
            }
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
