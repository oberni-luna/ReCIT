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

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    // TODO: set a message as read
    func readMessage(messageId: String) async throws {

    }

    // TODO: fetch transactions and associated messages
    func getOrFetchTransactions(modelContext: ModelContext) async throws -> [UserTransaction] {
        return []
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

}
