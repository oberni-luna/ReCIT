//
//  EditionDuplicatesModel.swift
//  ReCIT_iOS
//
//  What « Éditions » asks inventaire.io about the duplicates it found, and what it tells it: the
//  merge tasks already waiting on them, the merge itself, and « these two are not the same ».
//  PRD 0028.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class EditionDuplicatesModel: OptimisticMutating {
    private let apiService: APIServicing
    /// Reads the edition kept again after a merge. Optional so a test can leave the resync out.
    private let entityModel: EntityModel?
    var errorReporter: AppErrorReporter?
    /// The edition kept being read again after the last merge — for a test to wait on.
    private(set) var keptEditionResync: Task<Void, Never>?

    init(
        apiService: APIServicing,
        entityModel: EntityModel? = nil,
        errorReporter: AppErrorReporter? = nil
    ) {
        self.apiService = apiService
        self.entityModel = entityModel
        self.errorReporter = errorReporter
    }

    // MARK: - Fusionner

    /// Merges the edition of `pair` that is not `kept` into `kept`, on inventaire.io.
    ///
    /// **Not optimistic, on purpose.** A merge cannot be undone by this account — `revert-merge`
    /// is for dataadmins — and it changes the public database everybody uses. So the server is
    /// asked first, and the store follows only what it answered (ADR 0001's exception for
    /// deletions, and the rule of the lists):
    ///
    /// - `.merged`: the copies held here of the edition that disappears are filed under the one
    ///   kept, a work that opened on it opens on the one kept, the edition is deleted, and the
    ///   one kept is read again — in the background: the review goes on to the next pair at once.
    /// - `.reported`: the edition notes the task, and its row says « Doublon signalé ».
    ///
    /// Throws `MergeFailure` for a refusal; a `401` and any other failure go out as they came.
    /// Either way the store is not touched.
    func merge(
        _ pair: EditionDuplicatePair,
        keeping kept: EditionFacts,
        modelContext: ModelContext
    ) async throws -> MergeOutcome {
        guard let request = MergeChoice.request(keeping: kept, in: pair) else { throw MergeFailure.refused }

        let response: MergeResponseDTO?
        do {
            response = try await apiService.send(
                toEndpoint: "/api/entities/merge",
                method: "PUT",
                payload: request,
                debug: true
            )
        } catch {
            throw MergeFailure.classify(error)
        }
        guard let response, let outcome = MergeOutcome(response: response) else {
            throw NetworkError.badResponse
        }

        let goneUri: String = pair.other(than: kept.uri).uri
        switch outcome {
        case .merged:
            try fold(editionUri: goneUri, into: kept.uri, modelContext: modelContext)
            resync(keptUri: kept.uri, modelContext: modelContext)
        case .reported:
            if let gone = edition(uri: goneUri, modelContext: modelContext),
               gone.pendingMergeTargetUris.contains(request.to) == false {
                gone.pendingMergeTargetUris.append(request.to)
                try modelContext.save()
            }
        }
        return outcome
    }

    /// What a merge the server made means for the store: the edition `editionUri` is now a
    /// redirection to `keptUri`.
    private func fold(editionUri: String, into keptUri: String, modelContext: ModelContext) throws {
        guard let gone = edition(uri: editionUri, modelContext: modelContext) else { return }

        if let kept = edition(uri: keptUri, modelContext: modelContext) {
            for item in gone.items {
                item.edition = kept
            }
            kept.mergeWorks(gone.works)
        }
        let preferring: [Work] = try modelContext.fetch(
            FetchDescriptor<Work>(predicate: #Predicate { $0.preferredEditionUri == editionUri })
        )
        for work in preferring {
            work.preferredEditionUri = keptUri
        }

        modelContext.delete(gone)
        try modelContext.save()
    }

    /// Reads the edition kept again, the server having maybe moved claims onto it. Only that one:
    /// resyncing the whole work read every edition again when they were more than a day old —
    /// 7 742 of them for *L'Appel de la forêt* — and the review waited on it, its « Fusionner »
    /// spinning and its back button hidden. A failure leaves the store as `fold` left it.
    private func resync(keptUri: String, modelContext: ModelContext) {
        guard let entityModel else { return }
        keptEditionResync = Task {
            _ = try? await entityModel.refreshEdition(modelContext: modelContext, uri: keptUri)
        }
    }

    private func edition(uri: String, modelContext: ModelContext) -> Edition? {
        try? modelContext.fetch(FetchDescriptor<Edition>(predicate: #Predicate { $0.uri == uri })).first
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
        guard let claimUri = subject.mergeUri,
              let edition = edition(uri: subject.uri, modelContext: modelContext)
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
