//
//  UniqueCollisionTests.swift
//  ReCIT_iOSTests
//
//  What SwiftData does when a model is inserted under a `@Attribute(.unique)` value the store
//  already holds. Issue 0067 asked what removes a `Work`'s row; this is the answer, pinned down —
//  and the reason `ModelContext+Entities` exists.
//
//  If one of these starts failing after an OS update, SwiftData changed its rule: read
//  `ModelContext+Entities.swift` again before assuming the upsert is still needed as written.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Unique collision")
struct UniqueCollisionTests {

    @Test("A second insert under a held uri keeps one row, and empties what was stored locally")
    func secondInsertOverwritesTheHeldRow() throws {
        let context: ModelContext = try TestStore.makeContext()
        let held: Work = .init(uri: "wd:Q1", lastrevid: 1, title: "Held")
        held.applyEnrichedGenres(["Roman"])
        held.preferredEditionUri = "wd:Q2"
        context.insert(held)
        try context.save()

        context.insert(Work(uri: "wd:Q1", lastrevid: 2, title: "Fresh"))
        try context.save()

        let rows: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(rows.count == 1)
        #expect(rows.first === held)
        // The newcomer's values were poured into the held row, local fields included.
        #expect(held.title == "Fresh")
        #expect(held.genres.isEmpty)
        #expect(held.genresEnrichedAt == nil)
        #expect(held.preferredEditionUri == nil)
    }

    @Test("The newcomer stays registered with no row behind it, and what is written through it is lost")
    func newcomerIsARowlessTwin() throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(Work(uri: "wd:Q1", lastrevid: 1, title: "Held"))
        try context.save()

        let newcomer: Work = .init(uri: "wd:Q1", lastrevid: 2, title: "Fresh")
        context.insert(newcomer)
        try context.save()

        // It answers as if it were in the store — `isStillInTheStore` cannot tell.
        #expect(newcomer.isStillInTheStore)
        #expect(context.registeredModel(for: newcomer.persistentModelID) as Work? != nil)

        newcomer.applyEnrichedGenres(["Roman"])
        try context.save()

        let rows: [Work] = try context.fetch(FetchDescriptor<Work>())
        #expect(rows.count == 1)
        #expect(rows.first?.genres.isEmpty == true)
    }
}
