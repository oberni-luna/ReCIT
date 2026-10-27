//
//  EditionDuplicatesModel.swift
//  ReCIT_iOS
//
//  What « Éditions » asks inventaire.io about the duplicates it found: the merge tasks already
//  waiting on them. PRD 0028.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class EditionDuplicatesModel {
    private let apiService: APIServicing

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    // MARK: - Reports waiting on inventaire.io's team

    /// Records, on each of the work's editions, the merge tasks that wait on it as the edition
    /// that would disappear — « Doublon signalé », whoever reported it.
    ///
    /// Unlike a claim, an answer here is the whole truth for the uris asked: a task the team has
    /// closed is gone from it, and its tag goes with it. A call that fails changes nothing.
    func refreshPendingReports(modelContext: ModelContext, work: Work) async {
        let editionsByMergeUri: [String: Edition] = .init(
            work.editions.compactMap { edition in EditionFacts(edition: edition).mergeUri.map { ($0, edition) } },
            uniquingKeysWith: { first, _ in first }
        )
        guard editionsByMergeUri.isEmpty == false else { return }

        for batch in editionsByMergeUri.keys.sorted().splitInSubArrays(of: 50) {
            let endpoint: String = "/api/tasks/by-uris?uris=\(batch.joined(separator: "|"))&type=merge"
            guard let response: MergeTasksDTO = try? await apiService.fetchData(fromEndpoint: endpoint) else { continue }

            for uri in batch {
                guard let edition = editionsByMergeUri[uri], edition.isStillInTheStore else { continue }
                let targets: [String] = (response.tasks[uri] ?? [])
                    .filter { $0.state == nil && ($0.type ?? "merge") == "merge" }
                    .map(\.suggestionUri)
                if targets != edition.pendingMergeTargetUris {
                    edition.pendingMergeTargetUris = targets
                }
            }
        }
        try? modelContext.save()
    }
}
