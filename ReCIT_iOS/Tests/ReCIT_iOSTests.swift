//
//  ReCIT_iOSTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 11/08/2025.
//

import Testing
@testable import ReCIT_iOS

// MARK: - Integration Tests (live server)
// Requires network access to https://inventaire.io
// Uses a dedicated test account to avoid polluting real data.
// Run manually; not suitable for CI.

@Suite("Inventory Integration Tests")
struct InventoryIntegrationTests {
    private let authService: AuthService = .init(config: .init())
    private let api: APIService = .init(env: .production)

    private let testUsername: String = "OlivierB_test"
    private let testPassword: String = "Azerty1234!"

    @Test("Full scenario: login → check 3 items → add book → edit details → check 4 items")
    func inventoryScenario() async throws {
        // 1. Login
        try await authService.login(username: testUsername, password: testPassword)

        // 2. Fetch authenticated user to get their ID
        let userDTO: UserDTO = try #require(
            try await api.fetchData(fromEndpoint: "/api/user")
        )
        let userId: String = userDTO._id

        // 3. Check initial inventory count
        let inventoryBefore: InventoryResultDTO = try #require(
            try await api.fetchData(fromEndpoint: "/api/items/inventory-view?user=\(userId)")
        )
        #expect(inventoryBefore.totalItems == 3, "Expected 3 items before adding a book")

        // 4. Add a new item (isbn:9782072965821)
        let newItemPayload: NewItemDTO = .init(
            entity: "isbn:9782072965821",
            details: nil,
            notes: nil,
            transaction: TransactionType.inventorying.rawValue,
            visibility: [VisibilityAttributes.public.rawValue],
            shelves: []
        )
        let postResponse: PostItemResponseDTO = try #require(
            try await api.send(toEndpoint: "/api/items", payload: newItemPayload)
        )
        let createdItemId: String = postResponse.item._id

        // 5. Edit the details of the created item
        let updatePayload: UpdateItemsDTO = .init(
            ids: [createdItemId],
            attribute: "details",
            value: "Ma description de test"
        )
        let updateResponse: UpdateItemsResponseDTO = try #require(
            try await api.send(toEndpoint: "/api/items/bulk-update", method: "PUT", payload: updatePayload)
        )
        #expect(updateResponse.ok == true, "Expected bulk-update to succeed")

        // 6. Check inventory count is now 4
        let inventoryAfter: InventoryResultDTO = try #require(
            try await api.fetchData(fromEndpoint: "/api/items/inventory-view?user=\(userId)")
        )
        #expect(inventoryAfter.totalItems == 4, "Expected 4 items after adding a book")

        // Cleanup: remove the created item so the test account stays at 3 items
        let deletePayload: [String: [String]] = ["ids": [createdItemId]]
        let deleteResult: [String: Bool]? = try await api.send(
            toEndpoint: "/api/items/delete",
            payload: deletePayload
        )
        #expect(deleteResult?["ok"] == true, "Expected item deletion to succeed")
    }
}
