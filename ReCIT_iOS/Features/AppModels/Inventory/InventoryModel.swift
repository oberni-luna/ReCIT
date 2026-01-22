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

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func syncInventory(forUser: User, modelContext: ModelContext) async throws {
        print("## Sync inventory for user \(forUser.username)")
        guard forUser.lastItemAdded > forUser.lastInventorySync else {
            print("     -> no need to refresh")
            return
        }
        print("     -> syncing... ")

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

            forUser.lastInventorySync = Date().timeIntervalSince1970 * 1000 // to get milliseconds

            try modelContext.save()
        }
    }

    func postNewItem(modelContext: ModelContext, entityUri: String, transaction: TransactionType, visibility: [VisibilityAttributes], forUser: User) async throws -> InventoryItem {
        let payload = NewItemDTO(
            entity: entityUri,
            details: "",
            transaction: transaction.rawValue,
            visibility: visibility.map { $0.rawValue },
            shelves: []
        )

        guard let itemDTO: ItemDTO = try await apiService.post(toEndpoint: "/api/items?action=add", payload: payload) else {
            throw NetworkError.badResponse
        }

        let newItem = InventoryItem(itemDTO: itemDTO, forUser: forUser, baseUrl: apiService.baseUrl())
        modelContext.insert(newItem)
        try modelContext.save()
        return newItem
    }

    func searchEntity(query: String, lang: String? = "fr", limit: Int = 20, offset: Int = 0) async throws -> [SearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
        let language = lang ?? "fr"

        let endpoint = "/api/search?types=humans|works&search=\(encodedQuery)&lang=\(language)&limit=\(limit)&offset=\(offset)&exact=false"
        let response: SearchResultsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        return response?.results.map { result in
            SearchResult(
                id: result.id,
                uri: result.uri,
                title: result.label,
                description: result.description,
                imageUrl: absoluteImageUrl(result.image),
                score: result.score ?? 0,
                type: SearchResultType(rawValue: result.type) ?? .unknown
            )
        }
        .sorted { $0.score > $1.score } ?? []
    }

    func getAuthorWorks(modelContext: ModelContext, author: Author) async throws -> [Work]? {
        let endpoint = "/api/entities?action=author-works&uri=\(author.uri)&refresh=false"
        let response: AuthorWorksDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let authorWorkDTO = response?.works else {return nil}
        return try? await getOrFetchWorks(modelContext: modelContext, uris: authorWorkDTO.map(\.uri) )
    }

    func getWorkEdition(modelContext: ModelContext, work: Work) async throws -> [Edition]? {
        let endpoint = "/api/entities?action=reverse-claims&property=wdt:P629&value=\(work.uri)&refresh=false"
        let response: WorkEditionsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let editionUris = response?.uris else {return nil}

        return try? await getOrFetchEditions(modelContext: modelContext, uris: editionUris )
    }

    private func absoluteImageUrl(_ path: String?) -> String? {
        guard let path else { return nil }
        if path.hasPrefix("http") {
            return path
        }
        return "\(apiService.baseUrl())\(path)"
    }

    func getOrFetchWorks(modelContext: ModelContext, uris: [String]) async throws -> [Work]? {

        guard let worksDto = try await fetchEntities(modelContext: modelContext, uri: uris) else {
            return nil
        }

        return  worksDto.compactMap { workDto in
            Work(entityDTO: workDto, authors: [])
        }
    }

    func getOrFetchWork(modelContext: ModelContext, uri: String) async throws -> Work? {
        if let work = try? getLocalWork(modelContext: modelContext, uri: uri) {
            return work
        }

        guard let worksDto = try await fetchEntities(modelContext: modelContext, uri: [uri]) else {
            return nil
        }

        guard let workDto = worksDto.first else {
            return nil
        }

        return Work(entityDTO: workDto, authors: [])
    }

    func getOrFetchAuthor(modelContext: ModelContext, uri: String) async throws -> Author? {
        if let author = try? getLocalAuthor(modelContext: modelContext, uri: uri) {
            return author
        }

        guard let authorsDto = try await fetchEntities(modelContext: modelContext, uri: [uri]) else {
            return nil
        }

        guard let authorDto = authorsDto.first else {
            return nil
        }

        return Author(entityDTO: authorDto)
    }

    func getOrFetchEditions(modelContext: ModelContext, uris: [String]) async throws -> [Edition]? {

        guard let editionsDto = try await fetchEntities(modelContext: modelContext, uri: uris) else {
            return nil
        }

        return  editionsDto.compactMap { editionDto in
            Edition(entityDto: editionDto, baseUrl: apiService.baseUrl())
        }
    }

    private func fetchEntities(modelContext: ModelContext, uri: [String]) async throws -> [EntityResultDTO]? {

        let entityUrl: String = "/api/entities?action=by-uris&uris=\(uri.joined(separator: "|"))&attributes=info|labels|descriptions|claims|image&lang=fr"
        let resultsDto: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: entityUrl)

        return resultsDto.map { Array($0.entities.values) }
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
