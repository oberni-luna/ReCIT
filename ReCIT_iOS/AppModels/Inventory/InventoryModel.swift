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

class InventoryModel: ObservableObject {
    private static let unkownAuthorId: String = "unknown"
    private let apiService: APIService
    private var entityModel: EntityModel?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func start(entityModel: EntityModel) {
        self.entityModel = entityModel
    }

    // MARK: - Sync

    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        print("## Sync inventory for user \(forUser.username)")
        guard forUser.lastItemAdded > forUser.lastInventorySync else {
            print("     -> no need to refresh")
            return
        }
        print("     -> syncing... ")

        let result: InventoryResultDTO? = try await apiService.fetchData(fromEndpoint: "/api/items?action=inventory-view&user=\(forUser._id)")
        guard let result else { return }

        // Sync authors and works
        for authorUri: String in result.worksTree.author.keys {
            guard let authorWorkUris: [String] = result.worksTree.author[authorUri] else { continue }
            guard let workDTOs = try? await entityModel?.fetchEntities(modelContext: modelContext, uris: authorWorkUris) else { continue }

            if authorUri == InventoryModel.unkownAuthorId {
                for work in workDTOs {
                    modelContext.insert(Work(entityDTO: work, authors: [], apiService: apiService))
                }
            } else {
                guard let authors: [Author] = try await entityModel?.getOrFetchAuthors(modelContext: modelContext, uris: [authorUri]) else { continue }
                for work in workDTOs {
                    for author in authors {
                        author.works.append(Work(entityDTO: work, authors: authors, apiService: apiService))
                        modelContext.insert(author)
                    }
                }
            }
        }

        // Sync items and their editions
        for workUri in result.workUriItemsMap.keys {
            guard let relatedWork = try? entityModel?.getLocalWork(modelContext: modelContext, uri: workUri) else { continue }

            guard let ids: String = result.workUriItemsMap[workUri]?.joined(separator: "|") else { continue }
            let itemsUrl: String = "/api/items?ids=\(ids)&action=by-ids"

            guard let itemsDTO: ItemsDTO = try await apiService.fetchData(fromEndpoint: itemsUrl) else { continue }

            for itemDTO in itemsDTO.items {
                if let myItem = try? getLocalItem(modelContext: modelContext, id: itemDTO._id) {
                    if myItem.edition?.works.filter({ $0.uri == relatedWork.uri }).count == 0 {
                        myItem.edition?.works.append(relatedWork)
                    }
                    myItem.searchIndex = InventoryItem.buildSearchIndex(
                        ownerUsername: forUser.username,
                        authorNames: itemDTO.snapshot.`entity:authors`?.components(separatedBy: ",") ?? [],
                        title: itemDTO.snapshot.`entity:title`,
                        subtitle: itemDTO.snapshot.`entity:subtitle`
                    )
                    modelContext.insert(myItem)
                } else {
                    let myItem: InventoryItem = .init(itemDTO: itemDTO, forUser: forUser, apiService: apiService)
                    myItem.edition?.works.append(relatedWork)
                    modelContext.insert(myItem)
                }
            }
        }

        forUser.lastInventorySync = Date().timeIntervalSince1970 * 1000 // milliseconds
        try modelContext.save()
    }

    // MARK: - Item management

    func postNewItem(
        modelContext: ModelContext,
        entityUri: String,
        transaction: TransactionType,
        visibility: [VisibilityAttributes],
        forUser: User
    ) async throws -> InventoryItem {
        let payload: NewItemDTO = .init(
            entity: entityUri,
            details: "",
            notes: "",
            transaction: transaction.rawValue,
            visibility: visibility.map { $0.rawValue },
            shelves: []
        )

        guard let itemDTO: ItemDTO = try await apiService.send(toEndpoint: "/api/items", payload: payload) else {
            throw NetworkError.badResponse
        }

        let newItem: InventoryItem = .init(itemDTO: itemDTO, forUser: forUser, apiService: apiService)
        modelContext.insert(newItem)
        try modelContext.save()
        return newItem
    }

    func removeItem(_ item: InventoryItem, modelContext: ModelContext) async throws {
        let payload: [String: [String]] = ["ids": [item._id]]

        guard let ok: [String: Bool] = try await apiService.send(toEndpoint: "/api/items?action=delete-by-ids", payload: payload) else {
            throw NetworkError.badResponse
        }

        if let ok: Bool = ok["ok"], ok == true {
            modelContext.delete(item)
            try modelContext.save()
        }
    }

    func getOrFetchItem(modelContext: ModelContext, itemId: String) throws -> InventoryItem? {
        try getLocalItem(modelContext: modelContext, id: itemId)
    }

    // MARK: - Item updates

    func updateItemsTransaction(modelContext: ModelContext, items: [InventoryItem]) async throws {
        let response: UpdateItemsResponseDTO? = try await updateItems(
            ids: items.map(\._id),
            attribute: "transaction",
            value: items.first?.transaction.rawValue ?? ""
        )

        if response?.ok == true {
            try modelContext.save()
        } else {
            throw NSError(domain: "Failed to update items", code: 0, userInfo: nil)
        }
    }

    func updateItemsDetails(modelContext: ModelContext, items: [InventoryItem]) async throws {
        let response: UpdateItemsResponseDTO? = try await updateItems(
            ids: items.map(\._id),
            attribute: "details",
            value: items.first?.details ?? ""
        )

        if response?.ok == true {
            try modelContext.save()
        } else {
            throw NSError(domain: "Failed to update items", code: 0, userInfo: nil)
        }
    }

    func updateItems(ids: [String], attribute: String, value: String?) async throws -> UpdateItemsResponseDTO? {
        try await apiService.send(
            toEndpoint: "/api/items?action=bulk-update",
            method: "PUT",
            payload: UpdateItemsDTO(
                ids: ids,
                attribute: attribute,
                value: value ?? ""
            ),
            debug: true
        )
    }

    // MARK: - Private helpers

    private func getLocalItem(modelContext: ModelContext, id: String) throws -> InventoryItem? {
        let predicate: Predicate<InventoryItem> = #Predicate { object in
            object._id == id
        }
        let descriptor: FetchDescriptor<InventoryItem> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}
