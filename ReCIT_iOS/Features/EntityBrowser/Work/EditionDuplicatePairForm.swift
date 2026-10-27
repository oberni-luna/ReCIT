//
//  EditionDuplicatePairForm.swift
//  ReCIT_iOS
//
//  One pair of the duplicate review: the two editions, the one kept checked, and « Ce qui
//  diffère » between them. A Wikidata edition is always the one kept — inventaire.io only merges
//  towards it —, so the other one cannot be checked, and the note says why. PRD 0028.
//

import SwiftUI

struct EditionDuplicatePairForm: View {
    let pair: EditionDuplicatePair
    let editions: [Edition]
    let keptUri: String
    let copyCounts: [String: Int]
    let onKeep: (String) -> Void

    private var first: Edition? {
        editions.first { $0.uri == pair.first.uri }
    }

    private var second: Edition? {
        editions.first { $0.uri == pair.second.uri }
    }

    var body: some View {
        List {
            Section {
                ForEach([pair.first, pair.second], id: \.uri) { facts in
                    if let edition = editions.first(where: { $0.uri == facts.uri }) {
                        Button {
                            onKeep(facts.uri)
                        } label: {
                            EditionCell(
                                edition: edition,
                                leading: facts.uri == keptUri ? .on : .off,
                                copyCount: copyCounts[facts.uri]
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(MergeChoice.canKeep(facts, in: pair) == false)
                        .accessibilityIdentifier("e2e.duplicates.keep")
                    }
                }
            } header: {
                Text(pair.reason == .sameIsbn ? "duplicates.review.header.same_isbn" : "duplicates.review.header.probable")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            } footer: {
                Text(pair.first.isWikidata || pair.second.isWikidata ? "duplicates.review.keep_note.wikidata" : "duplicates.review.keep_note")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }

            if let first, let second {
                EditionDifferencesSection(
                    comparison: .init(first: .init(edition: first), second: .init(edition: second))
                )
            }
        }
        .listStyle(.insetGrouped)
        .applyListBackground()
    }
}
