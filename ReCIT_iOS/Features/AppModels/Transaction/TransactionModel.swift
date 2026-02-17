//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//
import SwiftData
import Foundation
import Combine
import AsyncAlgorithms

class TransactionModel: ObservableObject {
    private let apiService: APIService

    private var userModel: UserModel?
    private var inventoryModel: InventoryModel?

    init(fetchDataService: APIService = .init(env: .production), userModel: UserModel? = nil) {
        self.apiService = fetchDataService
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
            guard let requester:User = try await self.getTransactionUser(
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
//TODO: update transaction only if _rev hasn't change
//            let localTransaction: UserTransaction? = try getLocalTransaction(modelContext: modelContext, _id: transactionDTO._id)
//            
            let messages = try await self.fetchTransactionMessagesDTO(transactionId: transactionDTO._id).map { messageDTO in
                TransactionMessage(
                    _id: messageDTO._id,
                    user: [owner, requester].filter({messageDTO.user == $0._id}).first!,
                    message: messageDTO.message,
                    created: Date(timeIntervalSince1970: messageDTO.created / 1000)
                )
            }
            .sorted { $0.created < $1.created }

            modelContext.insert(UserTransaction(
                _id: transactionDTO._id,
                _rev: transactionDTO._rev,
                item: item,
                owner: owner,
                requester: requester,
                type: TransactionType(rawValue: transactionDTO.transaction) ?? .inventorying,
                created: Date(timeIntervalSince1970: transactionDTO.created / 1000),
                messages: messages,
                state: .init(rawValue: transactionDTO.state) ?? .requested,
                actions: transactionDTO.actions.map { action in
                    UserTransaction.TransactionAction.init(
                        action: UserTransaction.TransactionState(rawValue: action.action) ?? .requested,
                        timestamp: Date(timeIntervalSince1970: action.timestamp / 1000)
                    )
                },
                readStatus: UserTransaction.MessageReadStatus(owner: transactionDTO.read.owner, requester: transactionDTO.read.requester))
            )
        }

        try modelContext.save()

        return
    }

    private func getTransactionUser(modelContext: ModelContext, transactionUserId: String, user: User) async throws -> User? {
        if transactionUserId == user._id {
            return user
        } else {
            return try await userModel?.getOrFetchUsers(modelContext:modelContext, userIds: [transactionUserId]).first
        }
    }

    private func fetchTransactionMessagesDTO(transactionId: String) async throws -> [TransactionMessageDTO] {

        let transactionMessagesDTO: TransactionMessagesDTO? = try await apiService.fetchData(fromEndpoint: "/api/transactions?action=get-messages&transaction=\(transactionId)")
        guard let transactionMessagesDTO else { return [] }
        return transactionMessagesDTO.messages
    }

    func postRequest(itemId: String, message: String?) async throws {
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
            "action": "update-state",
            "state": newState.rawValue,
            "transaction": transaction._id
        ]

        guard let okStatus: OkStatusDTO = try await apiService.send(toEndpoint: "/api/transactions", method: "PUT", payload: payload) else {
            throw NetworkError.badResponse
        }
        
        if let message, !message.isEmpty {
            try await postMessage(transactionId: transaction._id, message: message)
        }
    }


    func postMessage(transactionId: String, message: String) async throws {
        guard !message.isEmpty else { return }
        
        let messagePayload = [
            "action": "message",
            "message": message,
            "transaction": transactionId
        ]

        guard let okStatus: OkStatusDTO = try await apiService.send(toEndpoint: "/api/transactions", payload: messagePayload) else {
            throw NetworkError.badResponse
        }
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
