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

    /// The `POST /api/transactions` body the server returns for a request action:
    /// the created transaction wrapped in `transaction`, plus a top-level
    /// `warnings` array. The array is what used to break decoding.
    private func requestResponseJSON(withWarnings: Bool) -> String {
        let warnings: String = withWarnings ? #","warnings":["some warning"]"# : ""
        return """
        {"transaction":{"_id":"t1","_rev":"1","item":"item-1","owner":"owner","requester":"req","transaction":"lending","state":"requested","created":1700000000000,"actions":[{"action":"request","timestamp":1700000000000}],"read":{"owner":true,"requester":false}}\(warnings)}
        """
    }

    // MARK: - Post request

    @Test("postRequest decodes a response carrying a top-level warnings array")
    func postRequestDecodesResponseWithWarnings() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/transactions", json: requestResponseJSON(withWarnings: true))
        let model: TransactionModel = .init(apiService: mock)

        // Regression: `warnings` (an array) previously crashed the
        // `[String: TransactionDTO]` decode with a typeMismatch.
        try await model.postRequest(itemId: "item-1", message: "May I borrow this?")

        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/transactions" && $0.method == "POST" })
    }

    @Test("postRequest also decodes a response without any warnings")
    func postRequestDecodesResponseWithoutWarnings() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/transactions", json: requestResponseJSON(withWarnings: false))
        let model: TransactionModel = .init(apiService: mock)

        try await model.postRequest(itemId: "item-1", message: "May I borrow this?")
    }

    @Test("postRequest rejects an empty message before hitting the network")
    func postRequestRejectsEmpty() async throws {
        let mock: MockAPIService = .init()
        let model: TransactionModel = .init(apiService: mock)

        await #expect(throws: TransactionError.self) {
            try await model.postRequest(itemId: "item-1", message: "")
        }
        #expect(mock.recordedRequests.isEmpty)
    }

    // MARK: - State machine entry point

    @Test("perform(request) posts through the state machine entry point")
    func performRequest() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, requester) = try makeTransaction(context: context)

        let mock: MockAPIService = .init()
        mock.stub("/api/transactions", json: requestResponseJSON(withWarnings: true))
        let model: TransactionModel = .init(apiService: mock, errorReporter: AppErrorReporter())

        try await model.perform(event: .request, on: transaction, message: "Please", author: requester, modelContext: context)

        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/transactions" && $0.method == "POST" })
    }

    @Test("perform(request) requires a message")
    func performRequestRequiresMessage() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, requester) = try makeTransaction(context: context)
        let model: TransactionModel = .init(apiService: MockAPIService())

        await #expect(throws: TransactionError.self) {
            try await model.perform(event: .request, on: transaction, message: "", author: requester, modelContext: context)
        }
    }

    @Test("perform(accept) applies the new state optimistically for the owner")
    func performAcceptApplies() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, _) = try makeTransaction(context: context)
        let owner: User = transaction.owner

        let mock: MockAPIService = .init()
        mock.stub("messages?id=", json: #"{"messages":[]}"#)
        mock.stub("/api/transactions/update-state", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: TransactionModel = .init(apiService: mock, errorReporter: reporter)

        try await model.perform(event: .accept, on: transaction, message: nil, author: owner, modelContext: context)

        #expect(transaction.state == .accepted) // optimistic, before the round-trip
        await model.inFlightTask?.value
        #expect(reporter.lastFailure == nil)
    }

    @Test("perform rejects an event the user can't trigger in the current state")
    func performRejectsInvalidTransition() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let (transaction, requester) = try makeTransaction(context: context)
        let model: TransactionModel = .init(apiService: MockAPIService())

        // The requester cannot accept their own request.
        await #expect(throws: TransactionError.self) {
            try await model.perform(event: .accept, on: transaction, message: nil, author: requester, modelContext: context)
        }
        #expect(transaction.state == .requested)
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
