//
//  InFlightWritesTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct InFlightWritesTests {
    private func storedItemID() throws -> PersistentIdentifier {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())
        context.insert(item)
        try context.save()
        return item.persistentModelID
    }

    @Test
    func `a model is in flight from the start of its write to its end`() throws {
        let writes: InFlightWrites = .init()
        let id: PersistentIdentifier = try storedItemID()

        writes.begin([id])
        #expect(writes.contains(id))

        writes.end([id])
        #expect(writes.contains(id) == false)
    }

    @Test
    func `two overlapping writes keep a model in flight until the second ends`() throws {
        let writes: InFlightWrites = .init()
        let id: PersistentIdentifier = try storedItemID()

        writes.begin([id])
        writes.begin([id])
        writes.end([id])
        #expect(writes.contains(id))

        writes.end([id])
        #expect(writes.contains(id) == false)
    }
}
