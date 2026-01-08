//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//
import SwiftData
import Foundation
import Combine

class InventoryModel: ObservableObject {
    private static let unkownAuthorId: String = "unknown"
    private let apiService: APIService
    @Published var myUser: User?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        let result: InventoryResultDTO? = try await apiService.fetchData(fromEndpoint: "/api/items?action=inventory-view&user=\(forUser._id)")
        if let result {
            // synchroniser l'auteur et les oeuvres
            for author in result.worksTree.author.keys {
                let authorWorks = result.worksTree.author[author] ?? []
                let uris = "\(authorWorks.joined(separator: "|"))"
                let url = "/api/entities?uris=\(uris)&action=by-uris&attributes=info&attributes=labels&attributes=descriptions&attributes=image&attributes=claims" //attributes=sitelinks&
                let worksDTO: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: url)

                guard let workDTOs = worksDTO?.entities else { continue }

                if author == InventoryModel.unkownAuthorId {
                    for work in workDTOs {
                        modelContext.insert(Work(entityDTO: work.value, authors: []))
                    }
                } else {
                    guard let authorModel = try await getOrFetchAuthor(modelContext: modelContext, uri: author) else { continue }
                    for work in workDTOs {
                        authorModel.works.append(Work(entityDTO: work.value, authors: [authorModel]))
                    }
                    modelContext.insert(authorModel)
                }
            }

            // synchroniser les items et leurs éditions
            for workUri in result.workUriItemsMap.keys {
                guard let relatedWork = try? getLocalWork(modelContext: modelContext, uri: workUri) else { continue }

                guard let ids: String = result.workUriItemsMap[workUri]?.joined(separator: "|") else { continue }
                let itemsUrl = "/api/items?ids=\(ids)&action=by-ids"
                
                guard let itemsDTO: ItemsDTO = try await apiService.fetchData(fromEndpoint: itemsUrl) else {continue}

                for itemDTO in itemsDTO.items {
                    if let myItem = try? getLocalItem(modelContext: modelContext, id: itemDTO._id) {
                        if myItem.edition?.works.filter({ $0.uri == relatedWork.uri }).count == 0 {
                            myItem.edition?.works.append(relatedWork)
                        }
                        modelContext.insert(myItem)
                    } else {
                        let myItem = InventoryItem(itemDTO: itemDTO, forUser: forUser, baseUrl: apiService.baseUrl())
                        myItem.edition?.works.append(relatedWork)
                        modelContext.insert(myItem)
                    }
                }
            }
            try modelContext.save()
        }
    }

    func postNewItem(modelContext: ModelContext, entity: Edition, transaction: TransactionType, visibility: [VisibilityAttributes]) async throws {

        
    }

    private func getOrFetchAuthor(modelContext: ModelContext, uri: String) async throws -> Author? {
        if let author = try? getLocalAuthor(modelContext: modelContext, uri: uri) {
            return author
        }

        let authorUrl: String = "/api/entities?uris=\(uri)&action=by-uris&attributes=info&attributes=labels&attributes=descriptions&attributes=image&attributes=claims"
        let authorsDto: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: authorUrl)

        guard let authorDto = authorsDto?.entities.values.first else {
            return nil
        }
        return Author(entityDTO: authorDto)
    }

    private func getLocalWork(modelContext: ModelContext, uri: String) throws -> Work? {
        let predicate = #Predicate<Work> { object in
            object.uri == uri
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func getLocalAuthor(modelContext: ModelContext, uri: String) throws -> Author? {
        let predicate = #Predicate<Author> { object in
            object.uri == uri
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    private func getLocalItem(modelContext: ModelContext, id: String) throws -> InventoryItem? {
        let predicate = #Predicate<InventoryItem> { object in
            object._id == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    

}
