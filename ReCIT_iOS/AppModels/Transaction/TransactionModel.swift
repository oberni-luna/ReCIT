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
final class TransactionModel {
    private let apiService: APIServicing

    private var userModel: UserModel?
    private var inventoryModel: InventoryModel?

    /// Surfaces a background (optimistic) failure so a long-lived view can show a
    /// SnackBar. Identifiable so observers can react to each new failure, even if
    /// the wrapped error compares equal to a previous one.
    struct SyncFailure: Identifiable {
        let id: UUID = .init()
        let error: Error
    }

    private(set) var lastFailure: SyncFailure?

    /// The most recent background reconcile/revert task spawned by an optimistic
    /// mutation. Exposed so tests can await completion; not observed by the UI.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    /// Marker prefix for locally-created placeholder messages that have not yet
    /// been confirmed by the server. Reconcile and revert use it to find them.
    private static let optimisticPrefix: String = "optimistic:"

    init(apiService: APIServicing, userModel: UserModel? = nil) {
        self.apiService = apiService
        self.userModel = userModel
    }

    func start(userModel: UserModel, inventoryModel: InventoryModel) {
        self.userModel = userModel
        self.inventoryModel = inventoryModel
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
        for optimistic in transaction.messages where optimistic._id.hasPrefix(Self.optimisticPrefix) {
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

        guard let _: [String: TransactionDTO] = try await apiService.send(toEndpoint: "/api/transactions", payload: payload) else {
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
            _id: "\(Self.optimisticPrefix)\(UUID().uuidString)",
            user: author,
            message: message,
            created: .now
        )
        modelContext.insert(placeholder)
        transaction.messages.append(placeholder)
        try modelContext.save()

        inFlightTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.postMessage(transactionId: transaction._id, message: message)
                try await self.reconcileMessages(transaction: transaction, modelContext: modelContext)
            } catch {
                self.remove(message: placeholder, from: transaction, modelContext: modelContext)
                self.lastFailure = .init(error: error)
            }
        }
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

        transaction.state = newState
        transaction.actions.append(.init(action: newState, timestamp: .now))

        var placeholder: TransactionMessage?
        if let message, !message.isEmpty {
            let optimistic: TransactionMessage = .init(
                _id: "\(Self.optimisticPrefix)\(UUID().uuidString)",
                user: author,
                message: message,
                created: .now
            )
            modelContext.insert(optimistic)
            transaction.messages.append(optimistic)
            placeholder = optimistic
        }
        try modelContext.save()

        inFlightTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.updateRequest(transaction: transaction, newState: newState, message: message)
                try await self.reconcileMessages(transaction: transaction, modelContext: modelContext)
            } catch {
                transaction.state = previousState
                transaction.actions = previousActions
                if let placeholder {
                    self.remove(message: placeholder, from: transaction, modelContext: modelContext)
                }
                try? modelContext.save()
                self.lastFailure = .init(error: error)
            }
        }
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

    private func remove(message: TransactionMessage, from transaction: UserTransaction, modelContext: ModelContext) {
        transaction.messages.removeAll { $0._id == message._id }
        modelContext.delete(message)
        try? modelContext.save()
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

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            String(localized: "error.empty_message")
        }
    }
}
