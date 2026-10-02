//
//  OptimisticRunnerTests.swift
//  ReCIT_iOSTests
//
//  The runner every optimistic write goes through, and what it does when a model its `revert`
//  or `reconcile` would write to has lost its row during the round trip.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Optimistic runner", .serialized)
struct OptimisticRunnerTests {

    @MainActor
    private final class Runner: OptimisticMutating {
        let errorReporter: AppErrorReporter? = .init()
    }

    private struct Refused: Error {}

    private func storedItem() throws -> (ModelContext, InventoryItem) {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(edition: Fixture.edition())
        context.insert(item)
        try context.save()
        return (context, item)
    }

    @Test("A failure puts the subject back and is reported")
    func failureReverts() async throws {
        let (context, item): (ModelContext, InventoryItem) = try storedItem()
        let runner: Runner = .init()

        await runner.optimistic(
            context,
            subjects: [item],
            apply: { item.details = "new" },
            revert: { item.details = "" },
            request: { throw Refused() }
        ).value

        #expect(item.details == "")
        #expect(runner.errorReporter?.lastFailure != nil)
    }

    @Test("A subject deleted during a failed request is not reverted, and the failure is still reported")
    func goneSubjectIsNotReverted() async throws {
        let (context, item): (ModelContext, InventoryItem) = try storedItem()
        let runner: Runner = .init()
        var reverted: Bool = false

        await runner.optimistic(
            context,
            subjects: [item],
            apply: { item.details = "new" },
            revert: { reverted = true },
            request: {
                context.delete(item)
                try context.save()
                throw Refused()
            }
        ).value

        #expect(reverted == false)
        #expect(runner.errorReporter?.lastFailure != nil)
    }

    @Test("A subject deleted during a successful request is not reconciled")
    func goneSubjectIsNotReconciled() async throws {
        let (context, item): (ModelContext, InventoryItem) = try storedItem()
        let runner: Runner = .init()
        var reconciled: Bool = false

        await runner.optimistic(
            context,
            subjects: [item],
            apply: { item.details = "new" },
            revert: {},
            request: {
                context.delete(item)
                try context.save()
            },
            reconcile: { reconciled = true }
        ).value

        #expect(reconciled == false)
        #expect(runner.errorReporter?.lastFailure == nil)
    }
}
