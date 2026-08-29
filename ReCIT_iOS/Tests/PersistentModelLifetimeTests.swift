//
//  PersistentModelLifetimeTests.swift
//  ReCIT_iOSTests
//
//  The one question every view that renders a model it does not own has to ask before reading
//  anything off it: is there still a row behind this?
//
//  These are the three moments that matter, in order — registered, deleted, saved — plus the
//  draft that was never inserted at all. What they cannot assert is the crash they exist to
//  prevent: reading a persisted property of an invalidated model is a trap, not a throw, so a
//  test that got it wrong would take the whole suite down rather than fail. The proof that the
//  guard works is `scripts/e2e.sh`, whose deletion step reproduced issue 0065 and now does not.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("PersistentModel lifetime")
struct PersistentModelLifetimeTests {

    @Test("An inserted, saved model is in the store")
    func insertedModelIsInTheStore() throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())
        context.insert(item)
        try context.save()

        #expect(item.isStillInTheStore)
    }

    @Test("Deleting takes it out of the store before the save")
    func deletedModelLeavesTheStoreImmediately() throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())
        context.insert(item)
        try context.save()

        context.delete(item)

        // The window this covers is the one the crash lived in: the delete has happened, the
        // save has not, and SwiftUI has already been told the model changed.
        #expect(item.isStillInTheStore == false)
    }

    @Test("And stays out of it after the save")
    func deletedModelStaysOutAfterTheSave() throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        #expect(item.isStillInTheStore == false)
    }

    @Test("A model that was never inserted is not in the store either")
    func draftModelIsNotInTheStore() throws {
        _ = try TestStore.makeContext()
        let draft: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())

        #expect(draft.isStillInTheStore == false)
    }

    @Test("The answer is the same for every model type")
    func theGuardIsNotSpecificToInventoryItems() throws {
        let context: ModelContext = try TestStore.makeContext()
        let shelf: Shelf = .init(
            _id: "shelf-1",
            _rev: "rev-1",
            name: "Romans",
            slug: "romans",
            shelfDescription: "",
            ownerId: "user-1",
            visibility: [],
            colorHex: nil,
            created: .init(timeIntervalSince1970: 0),
            updated: nil
        )
        context.insert(shelf)
        try context.save()
        #expect(shelf.isStillInTheStore)

        context.delete(shelf)
        try context.save()
        #expect(shelf.isStillInTheStore == false)
    }
}
