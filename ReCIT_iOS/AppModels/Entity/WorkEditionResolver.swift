//
//  WorkEditionResolver.swift
//  ReCIT_iOS
//
//  Turns a work into the one edition the app should open, and writes nothing.
//
//  `/api/search` cannot return editions, so a search for a book returns works; this is what
//  stands between a tapped result and a book (ADR 0002, Move 3). Two calls:
//
//    1. `reverse-claims` on `wdt:P629` — the uris of the work's editions
//    2. `by-uris` in batches of 50 — their language, title claim and cover
//
//  **It deliberately does not go through `EntityModel.getWorkEditions`.** That method inserts
//  every edition it reads, resolves each one's works, and saves — 127 objects for *1984*, on one
//  tap, on the main actor. This resolver ranks over DTOs and hands back a single uri; persisting
//  it is the caller's job, through the existing `refreshEdition`, which upserts (ADR 0001,
//  invariant 2).
//
//  `attributes` asks for `info` even though nothing else here needs it: the edition's language
//  arrives as `originalLang`, and that field is only returned under `info`. The attribute it
//  drops against `EntityModel.fetchEntities` is `descriptions`. The saving that matters is not
//  the payload — it is that nothing reaches the store.
//
//  Measured against production, 2026-09-11: ~750 ms and ~60 KB per work. `reverse-claims`
//  ignores `limit` (`unexpected parameter`), so the full list always comes back and there is no
//  server-side way to bound this.
//
//  See PRD 0014.
//

import Foundation

@MainActor
struct WorkEditionResolver {
    /// The language the app reads in. Hard-coded, like the twelve other `"fr"` in this codebase;
    /// a real preferred-language setting is a feature of its own (PRD 0014, Out of Scope).
    static let preferredLang: String = "fr"

    /// How many uris `by-uris` takes at once — the same batch size `EntityModel.fetchEntities`
    /// uses, so the two never disagree about what the server accepts.
    private static let batchSize: Int = 50

    private let apiService: APIServicing

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    /// The uri of the edition to open for `workUri`, or `nil` when the work has no edition at
    /// all — which happens, and which the caller renders rather than swallows.
    ///
    /// `heldEditionUris` are the editions already on this device, mine or a friend's. They enter
    /// by parameter rather than by a lookup: this type never sees a `ModelContext`.
    func bestEditionUri(
        forWorkUri workUri: String,
        originalLang: String?,
        heldEditionUris: Set<String> = [],
        preferredLang: String = Self.preferredLang
    ) async throws -> String? {
        let uris: [String] = try await editionUris(ofWork: workUri)
        guard uris.isEmpty == false else { return nil }

        let candidates: [EditionRelevance.Candidate] = try await candidates(
            forEditionUris: uris,
            heldEditionUris: heldEditionUris
        )

        return EditionRelevance.best(
            among: candidates,
            preferredLang: preferredLang,
            originalLang: originalLang
        )?.id
    }

    // MARK: - The two calls

    private func editionUris(ofWork workUri: String) async throws -> [String] {
        let endpoint: String = "/api/entities/reverse-claims"
            + "?property=\(WikidataProperty.editionOf.rawValue)&value=\(workUri)&refresh=false"
        let response: WorkEditionsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        return response?.uris ?? []
    }

    /// The candidates, **in the order `reverse-claims` gave them**. The `by-uris` envelope is a
    /// dictionary, and iterating one would make the ranking's tie-break depend on hash order —
    /// the same search would then open two different books on two runs. So the requested uris
    /// drive the order, and anything the server returned under a key nobody asked for (a
    /// redirect resolving to its canonical uri) is appended in a sorted, therefore stable, tail
    /// rather than dropped.
    private func candidates(
        forEditionUris uris: [String],
        heldEditionUris: Set<String>
    ) async throws -> [EditionRelevance.Candidate] {
        var entities: [String: EditionCandidateDTO] = [:]

        for batch in uris.splitInSubArrays(of: Self.batchSize) {
            let endpoint: String = "/api/entities/by-uris"
                + "?uris=\(batch.joined(separator: "|"))"
                + "&attributes=info|labels|claims|image&lang=\(Self.preferredLang)"
            let response: EditionCandidatesDTO? = try await apiService.fetchData(fromEndpoint: endpoint)
            entities.merge(response?.entities ?? [:]) { current, _ in current }
        }

        var ordered: [EditionCandidateDTO] = uris.compactMap { entities[$0] }
        let seen: Set<String> = .init(ordered.map(\.uri))
        ordered.append(
            contentsOf: entities.values
                .filter { seen.contains($0.uri) == false }
                .sorted { $0.uri < $1.uri }
        )

        return ordered.map { dto in
            .init(
                id: dto.uri,
                lang: dto.originalLang,
                hasTitle: dto.hasTitle,
                hasCover: dto.hasCover,
                isHeld: heldEditionUris.contains(dto.uri),
                isSingleWork: dto.isSingleWork
            )
        }
    }
}
