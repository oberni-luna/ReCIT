//
//  ModelContext+Entities.swift
//  ReCIT_iOS
//
//  The one way an author, a work or an edition gets into the store.
//
//  **Never build one and insert it.** `uri` is `@Attribute(.unique)` on all three, and SwiftData
//  settles a second insert under the same uri by keeping one row and pouring the newcomer's values
//  into it: every field the app computed or asked for locally — a work's `genres` and
//  `preferredEditionUri`, an edition's `works` and `dominantColorHex` — comes back empty. The
//  newcomer, meanwhile, stays registered with no row behind it, so what is written through it is
//  lost, and once it has been turned back into a fault a write raises from inside CoreData. That is
//  issue 0067; `UniqueCollisionTests` pins the behaviour down.
//
//  So everything here looks the uri up first, merges into what is there through the models' own
//  `update(entityDTO:)` — which never lets a sparse payload wipe a field — and inserts only what
//  is missing. Relationships are merged by union on the uri: a work listed under each of its two
//  authors keeps both, and asking twice adds nothing. ADR 0001, invariant 2.
//
//  An extension on the context rather than methods on `EntityModel`: `InventoryModel` only gets
//  its `EntityModel` once `start()` has run, and a sync must not be able to fall back to building
//  entities by hand because that dependency is not there yet.
//

import Foundation
import SwiftData

extension ModelContext {

    /// Merges `dtos` into the store's authors, and answers them in order.
    @discardableResult
    func upsertAuthors(_ dtos: [EntityResultDTO], apiService: APIServicing) throws -> [Author] {
        let uris: [String] = dtos.map(\.uri)
        let existing: [Author] = try fetch(FetchDescriptor<Author>(predicate: #Predicate { uris.contains($0.uri) }))
        var byUri: [String: Author] = .init(existing.map { ($0.uri, $0) }, uniquingKeysWith: { first, _ in first })

        return dtos.map { dto in
            if let author = byUri[dto.uri] {
                author.update(entityDTO: dto, apiService: apiService)
                return author
            }
            let author: Author = .init(entityDTO: dto, apiService: apiService)
            insert(author)
            byUri[dto.uri] = author
            return author
        }
    }

    /// Merges `dto` into the store's works, adding `authors` to the ones it already has.
    @discardableResult
    func upsertWork(_ dto: EntityResultDTO, authors: [Author], apiService: APIServicing) throws -> Work {
        let uri: String = dto.uri
        if let work = try fetch(FetchDescriptor<Work>(predicate: #Predicate { $0.uri == uri })).first {
            work.update(entityDTO: dto, apiService: apiService)
            work.mergeAuthors(authors)
            return work
        }
        let work: Work = .init(entityDTO: dto, authors: [], apiService: apiService)
        insert(work)
        work.mergeAuthors(authors)
        return work
    }

    /// Merges `dto` into the store's editions, adding `works` to the ones it already has.
    @discardableResult
    func upsertEdition(_ dto: EntityResultDTO, works: [Work], apiService: APIServicing) throws -> Edition {
        let uri: String = dto.uri
        if let edition = try fetch(FetchDescriptor<Edition>(predicate: #Predicate { $0.uri == uri })).first {
            edition.update(entityDto: dto, apiService: apiService)
            edition.mergeWorks(works)
            return edition
        }
        let edition: Edition = .init(entityDto: dto, apiService: apiService)
        insert(edition)
        edition.mergeWorks(works)
        return edition
    }

    /// The edition an inventory item names, from the store when it is there, otherwise made from
    /// the item's snapshot.
    ///
    /// An edition already held is left as it is: the snapshot is the item's copy of a few of the
    /// entity's fields, and the entity itself — fetched by `EntityModel` — is the better source.
    func edition(uri: String, snapshot: EntitySnapshotDTO, apiService: APIServicing) throws -> Edition {
        if let edition = try fetch(FetchDescriptor<Edition>(predicate: #Predicate { $0.uri == uri })).first {
            return edition
        }
        let edition: Edition = .init(uri: uri, entitySnapshotDTO: snapshot, apiService: apiService)
        insert(edition)
        return edition
    }
}
