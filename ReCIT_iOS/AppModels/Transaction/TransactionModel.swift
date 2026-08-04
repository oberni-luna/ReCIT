//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//
import SwiftData
import Foundation
import AsyncAlgorithms

@MainActor
@Observable
final class TransactionModel: OptimisticMutating {
    private let apiService: APIServicing

    private var userModel: UserModel?
    private var inventoryModel: InventoryModel?

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// The most recent background reconcile/revert task spawned by an optimistic
    /// mutation. Exposed so tests can await completion; not observed by the UI.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(apiService: APIServicing, userModel: UserModel? = nil, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.userModel = userModel
        self.errorReporter = errorReporter
    }

    func start(userModel: UserModel, inventoryModel: InventoryModel, errorReporter: AppErrorReporter) {
        self.userModel = userModel
        self.inventoryModel = inventoryModel
        self.errorReporter = errorReporter
    }

    // TODO: set a message as read
    func readMessage(messageId: String) async throws {

    }

    // fetch transactions and associated messages
    func syncTransactions(modelContext: ModelContext) async throws {
        guard let user = userModel?.myUser else {
            return
        }

        let transactions: TransactionsDTO? = try await apiService.fetchData(fromEndpoint: "/api/transactions")
        guard let transactions else { return }

        for transactionDTO in transactions.transactions {
            guard let requester: User = try await self.getTransactionUser(
                modelContext: modelContext,
                transactionUserId: transactionDTO.requester,
                user: user
            ) else {
                continue
            }

            guard let owner: User = try await self.getTransactionUser(
                modelContext: modelContext,
                transactionUserId: transactionDTO.owner,
                user: user
            ) else {
                continue
            }

            guard let item: InventoryItem = try inventoryModel?.getOrFetchItem(modelContext: modelContext, itemId: transactionDTO.item) else {
                continue
            }

            let messageDTOs: [TransactionMessageDTO] = try await self.fetchTransactionMessagesDTO(transactionId: transactionDTO._id)
            let state: UserTransaction.TransactionState = .init(rawValue: transactionDTO.state) ?? .requested
            let type: TransactionType = .init(rawValue: transactionDTO.transaction) ?? .inventorying
            let actions: [UserTransaction.TransactionAction] = transactionDTO.actions.map { action in
                .init(
                    action: UserTransaction.TransactionState(rawValue: action.action) ?? .requested,
                    timestamp: Date(timeIntervalSince1970: action.timestamp / 1000)
                )
            }
            let readStatus: UserTransaction.MessageReadStatus = .init(owner: transactionDTO.read.owner, requester: transactionDTO.read.requester)

            // Upsert in place so an already-displayed transaction keeps its object
            // identity (and stays reactive) instead of being deleted and re-created.
            if let existing = try getLocalTransaction(modelContext: modelContext, _id: transactionDTO._id) {
                existing._rev = transactionDTO._rev
                existing.item = item
                existing.owner = owner
                existing.requester = requester
                existing.type = type
                existing.state = state
                existing.actions = actions
                existing.readStatus = readStatus
                upsertMessages(dtos: messageDTOs, into: existing, participants: [owner, requester], modelContext: modelContext)
            } else {
                let transaction: UserTransaction = .init(
                    _id: transactionDTO._id,
                    _rev: transactionDTO._rev,
                    item: item,
                    owner: owner,
                    requester: requester,
                    type: type,
                    created: Date(timeIntervalSince1970: transactionDTO.created / 1000),
                    messages: [],
                    state: state,
                    actions: actions,
                    readStatus: readStatus
                )
                modelContext.insert(transaction)
                upsertMessages(dtos: messageDTOs, into: transaction, participants: [owner, requester], modelContext: modelContext)
            }
        }

        try modelContext.save()

        return
    }

    /// Merges server message DTOs into a transaction's `messages` relationship by
    /// `_id`, inserting the missing ones and dropping any not-yet-confirmed
    /// optimistic placeholders. Existing confirmed messages are left untouched.
    private func upsertMessages(
        dtos: [TransactionMessageDTO],
        into transaction: UserTransaction,
        participants: [User],
        modelContext: ModelContext
    ) {
        for optimistic in transaction.messages where OptimisticID.isOptimistic(optimistic._id) {
            transaction.messages.removeAll { $0._id == optimistic._id }
            modelContext.delete(optimistic)
        }

        let existingIds: Set<String> = Set(transaction.messages.map(\._id))
        for dto in dtos where !existingIds.contains(dto._id) {
            guard let messageUser = participants.first(where: { $0._id == dto.user }) else { continue }
            let message: TransactionMessage = .init(messageDTO: dto, user: messageUser)
            modelContext.insert(message)
            transaction.messages.append(message)
        }
    }

    private func getTransactionUser(modelContext: ModelContext, transactionUserId: String, user: User) async throws -> User? {
        if transactionUserId == user._id {
            return user
        } else {
            return try await userModel?.getOrFetchUsers(modelContext:modelContext, userIds: [transactionUserId]).first
        }
    }

    private func fetchTransactionMessagesDTO(transactionId: String) async throws -> [TransactionMessageDTO] {

        let transactionMessagesDTO: TransactionMessagesDTO? = try await apiService.fetchData(fromEndpoint: "/api/transactions/messages?id=\(transactionId)")
        guard let transactionMessagesDTO else { return [] }
        return transactionMessagesDTO.messages
    }

    func postRequest(itemId: String, message: String?) async throws {
        guard message?.isEmpty == false else { throw TransactionError.emptyMessage }

        let payload = [
            "action": "request",
            "item": itemId,
            "message": message ?? ""
        ]

        guard let _: PostTransactionResponseDTO = try await apiService.send(toEndpoint: "/api/transactions", payload: payload) else {
            throw NetworkError.badResponse
        }
    }

    func updateRequest(transaction: UserTransaction, newState: UserTransaction.TransactionState, message: String?) async throws {
        let payload = [
            "state": newState.rawValue,
            "id": transaction._id
        ]

        guard let _: OkStatusDTO = try await apiService.send(toEndpoint: "/api/transactions/update-state", method: "PUT", payload: payload) else {
            throw NetworkError.badResponse
        }
        
        if let message, !message.isEmpty {
            try await postMessage(transactionId: transaction._id, message: message)
        }
    }


    func postMessage(transactionId: String, message: String) async throws {
        guard !message.isEmpty else { throw TransactionError.emptyMessage }

        let messagePayload = [
            "message": message,
            "id": transactionId
        ]

        guard let _: OkStatusDTO = try await apiService.send(toEndpoint: "/api/transactions/messages", payload: messagePayload) else {
            throw NetworkError.badResponse
        }
    }

    // MARK: - State machine entry point

    /// The single entry point for a user-triggered transaction move. Validates the
    /// event against the state machine (`TransactionStateMachine`), enforces the
    /// message rule, then routes to the creation (`request`) or optimistic
    /// state-change path. Throws `TransactionError.invalidTransition` if the event
    /// isn't allowed for this user in the transaction's current state.
    func perform(
        event: TransactionEvent,
        on transaction: UserTransaction,
        message: String?,
        author: User,
        modelContext: ModelContext
    ) async throws {
        // A request creates a brand-new transaction: there is no local object to
        // mutate yet, so it stays server-first then syncs.
        if event == .request {
            guard message?.isEmpty == false else { throw TransactionError.emptyMessage }
            try await postRequest(itemId: transaction.item._id, message: message ?? "")
            try await syncTransactions(modelContext: modelContext)
            return
        }

        guard let transition = transaction.availableTransitions(for: author).first(where: { $0.event == event }) else {
            throw TransactionError.invalidTransition
        }

        if transition.requiresMessage, message?.isEmpty != false {
            throw TransactionError.emptyMessage
        }

        try updateStateOptimistic(
            transaction: transaction,
            newState: transition.to,
            message: message?.isEmpty == false ? message : nil,
            author: author,
            modelContext: modelContext
        )
    }

    // MARK: - Optimistic mutations

    /// Appends the message to the local store immediately (so the UI reacts at
    /// once), then posts it in the background. On failure the placeholder is
    /// removed and `lastFailure` is published; on success the local store is
    /// reconciled with the server's canonical message.
    func postMessageOptimistic(
        transaction: UserTransaction,
        message: String,
        author: User,
        modelContext: ModelContext
    ) throws {
        guard !message.isEmpty else { throw TransactionError.emptyMessage }

        let placeholder: TransactionMessage = .init(
            _id: OptimisticID.make(),
            user: author,
            message: message,
            created: .now
        )

        inFlightTask = optimistic(
            modelContext,
            apply: {
                modelContext.insert(placeholder)
                transaction.messages.append(placeholder)
            },
            revert: {
                transaction.messages.removeAll { $0._id == placeholder._id }
                modelContext.delete(placeholder)
            },
            request: { [weak self] in
                try await self?.postMessage(transactionId: transaction._id, message: message)
            },
            reconcile: { [weak self] in
                try await self?.reconcileMessages(transaction: transaction, modelContext: modelContext)
            }
        )
    }

    /// Applies the new state (and optional message) to the local store immediately,
    /// then performs the request in the background. On failure the previous state,
    /// actions and any optimistic message are reverted and `lastFailure` is published.
    func updateStateOptimistic(
        transaction: UserTransaction,
        newState: UserTransaction.TransactionState,
        message: String?,
        author: User,
        modelContext: ModelContext
    ) throws {
        let previousState: UserTransaction.TransactionState = transaction.state
        let previousActions: [UserTransaction.TransactionAction] = transaction.actions

        var placeholder: TransactionMessage?
        if let message, !message.isEmpty {
            placeholder = .init(_id: OptimisticID.make(), user: author, message: message, created: .now)
        }

        inFlightTask = optimistic(
            modelContext,
            apply: {
                transaction.state = newState
                transaction.actions.append(.init(action: newState, timestamp: .now))
                if let placeholder {
                    modelContext.insert(placeholder)
                    transaction.messages.append(placeholder)
                }
            },
            revert: {
                transaction.state = previousState
                transaction.actions = previousActions
                if let placeholder {
                    transaction.messages.removeAll { $0._id == placeholder._id }
                    modelContext.delete(placeholder)
                }
            },
            request: { [weak self] in
                try await self?.updateRequest(transaction: transaction, newState: newState, message: message)
            },
            reconcile: { [weak self] in
                try await self?.reconcileMessages(transaction: transaction, modelContext: modelContext)
            }
        )
    }

    /// Replaces optimistic placeholders with the server's canonical messages.
    private func reconcileMessages(transaction: UserTransaction, modelContext: ModelContext) async throws {
        let dtos: [TransactionMessageDTO] = try await fetchTransactionMessagesDTO(transactionId: transaction._id)
        upsertMessages(
            dtos: dtos,
            into: transaction,
            participants: [transaction.owner, transaction.requester],
            modelContext: modelContext
        )
        try modelContext.save()
    }

    private func getLocalTransaction(modelContext: ModelContext, _id: String) throws -> UserTransaction? {
        let predicate = #Predicate<UserTransaction> { object in
            object._id == _id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func deleteLocalTransactions(modelContext: ModelContext) throws {
        try modelContext.delete(model: UserTransaction.self)
    }
}

enum TransactionError: LocalizedError {
    case emptyMessage
    case invalidTransition

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            String(localized: "error.empty_message")
        case .invalidTransition:
            String(localized: "error.invalid_transition")
        }
    }
}
