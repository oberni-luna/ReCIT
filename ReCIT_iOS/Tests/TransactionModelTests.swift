//
//  TransactionModelTests.swift
//  ReCIT_iOSTests
//
//  Covers the optimistic transaction mutations: local-first writes, background
//  reconcile on success, and revert + error surfacing on failure.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("TransactionModel optimistic", .serialized)
struct TransactionModelTests {

    // MARK: - Fixtures

    private func makeTransaction(context: ModelContext) throws -> (transaction: UserTransaction, author: User) {
        let owner: User = Fixture.user(id: "owner", username: "owner")
        let requester: User = Fixture.user(id: "req", username: "requester")
        let item: InventoryItem = Fixture.inventoryItem(id: "item-1", ownerId: "owner", edition: Fixture.edition(uri: "isbn:1"))

        let transaction: UserTransaction = .init(
            _id: "t1",
            _rev: "1",
            item: item,
            owner: owner,
            requester: requester,
            type: .lending,
            created: .init(timeIntervalSince1970: 0),
            messages: [],
            state: .requested,
            actions: [.init(action: .requested, timestamp: .init(timeIntervalSince1970: 0))],
            readStatus: .init(owner: true, requester: true)
        )
        context.insert(owner)
        context.insert(requester)
        context.insert(item)
        context.insert(transaction)
        try context.save()
        return (transaction, requester)
    }

    /// One server message from the requester, wrapped in the messages envelope.
    private func serverMessagesJSON(id: String, userId: String, text: String) -> String {
        """
        {"messages":[{"_id":"\(id)","_rev":"1","user":"\(userId)","message":"\(text)","created":1700000000000,"transaction":"t1"}]}
        """
    }

    // MARK: - Post message

    @Test("postMessageOptimistic inserts the message locally before any network round-trip")
    func postMessageInsertsImmediately() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, author) = try makeTransaction(context: context)

        let mock: MockAPIService = .init()
        // GET reconcile (more specific match first), then POST.
        mock.stub("messages?id=", json: serverMessagesJSON(id: "m1", userId: "req", text: "Hello"))
        mock.stub("/api/transactions/messages", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: TransactionModel = .init(apiService: mock, errorReporter: reporter)

        try model.postMessageOptimistic(transaction: transaction, message: "Hello", author: author, modelContext: context)

        // Instant, before the background task resolves.
        #expect(transaction.messages.count == 1)

        await model.inFlightTask?.value

        // Reconciled: optimistic placeholder replaced by the server message.
        #expect(transaction.messages.count == 1)
        #expect(transaction.messages.first?._id == "m1")
        #expect(reporter.lastFailure == nil)
    }

    @Test("postMessageOptimistic reverts the local message and surfaces an error on failure")
    func postMessageRevertsOnFailure() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, author) = try makeTransaction(context: context)

        let mock: MockAPIService = .init()
        mock.stub("/api/transactions/messages", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: TransactionModel = .init(apiService: mock, errorReporter: reporter)

        try model.postMessageOptimistic(transaction: transaction, message: "Hello", author: author, modelContext: context)
        #expect(transaction.messages.count == 1) // shown optimistically

        await model.inFlightTask?.value

        #expect(transaction.messages.isEmpty)     // reverted
        #expect(reporter.lastFailure != nil)       // error surfaced
    }

    @Test("postMessageOptimistic rejects an empty message synchronously")
    func postMessageRejectsEmpty() throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, author) = try makeTransaction(context: context)
        let model: TransactionModel = .init(apiService: MockAPIService())

        #expect(throws: TransactionError.self) {
            try model.postMessageOptimistic(transaction: transaction, message: "", author: author, modelContext: context)
        }
        #expect(transaction.messages.isEmpty)
    }

    // MARK: - State change

    @Test("updateStateOptimistic applies the new state immediately")
    func updateStateAppliesImmediately() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, author) = try makeTransaction(context: context)

        let mock: MockAPIService = .init()
        mock.stub("messages?id=", json: #"{"messages":[]}"#)
        mock.stub("/api/transactions/update-state", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: TransactionModel = .init(apiService: mock, errorReporter: reporter)

        try model.updateStateOptimistic(transaction: transaction, newState: .accepted, message: nil, author: author, modelContext: context)

        #expect(transaction.state == .accepted)
        #expect(transaction.actions.contains { $0.action == .accepted })

        await model.inFlightTask?.value
        #expect(transaction.state == .accepted)
        #expect(reporter.lastFailure == nil)
    }

    @Test("updateStateOptimistic reverts state and actions on failure")
    func updateStateRevertsOnFailure() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, author) = try makeTransaction(context: context)
        let actionsBefore: Int = transaction.actions.count

        let mock: MockAPIService = .init()
        mock.stub("/api/transactions/update-state", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: TransactionModel = .init(apiService: mock, errorReporter: reporter)

        try model.updateStateOptimistic(transaction: transaction, newState: .accepted, message: nil, author: author, modelContext: context)
        #expect(transaction.state == .accepted) // optimistic

        await model.inFlightTask?.value

        #expect(transaction.state == .requested)          // reverted
        #expect(transaction.actions.count == actionsBefore) // reverted
        #expect(reporter.lastFailure != nil)
    }
}
