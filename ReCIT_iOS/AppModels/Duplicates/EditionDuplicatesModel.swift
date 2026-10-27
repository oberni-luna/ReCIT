//
//  EditionDuplicatesModel.swift
//  ReCIT_iOS
//
//  What « Éditions » asks inventaire.io about the duplicates it found, and what it tells it: the
//  merge tasks already waiting on them, and « these two are not the same ». PRD 0028.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class EditionDuplicatesModel: OptimisticMutating {
    private let apiService: APIServicing
    var errorReporter: AppErrorReporter?

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    // MARK: - « Ce ne sont pas les mêmes »

    /// Declares the two editions of `pair` different on inventaire.io: `wdt:P1889` (« different
    /// from »), which the server accepts on an edition, written on the pair's `inv:` edition —
    /// the one that would have disappeared, when both are. Everybody stops being offered the pair,
    /// and the server will refuse to merge it.
    ///
    /// Optimistic (ADR 0001, invariant 3): a claim added in place has a clean inverse. The pair
    /// leaves the review at once; a refusal brings it back and is reported.
    @discardableResult
    func markNotTheSame(_ pair: EditionDuplicatePair, modelContext: ModelContext) -> Task<Void, Never>? {
        let kept: EditionFacts = MergeChoice.proposedKeep(in: pair)
        let dropped: EditionFacts = pair.other(than: kept.uri)
        let subject: EditionFacts = dropped.mergeUri != nil ? dropped : kept
        let subjectUri: String = subject.uri
        guard let claimUri = subject.mergeUri,
              let edition = try? modelContext.fetch(FetchDescriptor<Edition>(predicate: #Predicate { $0.uri == subjectUri })).first
        else { return nil }

        let other: String = pair.other(than: subject.uri).uri
        guard edition.differentFromUris.contains(other) == false else { return nil }
        let update: EditionClaimUpdate = .init(
            uri: claimUri,
            property: WikidataProperty.differentFrom.rawValue,
            oldValue: nil,
            newValue: .string(other)
        )

        return optimistic(
            modelContext,
            subjects: [edition],
            apply: {
                edition.differentFromUris.append(other)
            },
            revert: {
                edition.differentFromUris.removeAll { $0 == other }
            },
            request: { [apiService] in
                let _: OkStatusDTO? = try await apiService.send(
                    toEndpoint: "/api/entities/update-claim",
                    method: "PUT",
                    payload: update,
                    debug: false
                )
            }
        )
    }

    // MARK: - Copies

    /// How many copies of `uri` this account can see on inventaire.io — « 3 exemplaires » in the
    /// review. Not every copy in the database: a private one is not counted. `nil` when the call
    /// fails, and the review then says nothing.
    func copyCount(uri: String) async -> Int? {
        let response: ItemsTotalDTO? = try? await apiService.fetchData(
            fromEndpoint: "/api/items/by-entities?uris=\(uri)&limit=1"
        )
        return response?.total
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
