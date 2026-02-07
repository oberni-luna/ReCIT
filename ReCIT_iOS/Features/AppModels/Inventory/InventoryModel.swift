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
            for authorUri: String in result.worksTree.author.keys {
                guard let authorWorkUris: [String] = result.worksTree.author[authorUri] else { continue }
                guard let workDTOs = try? await fetchEntities(modelContext: modelContext, uri: authorWorkUris) else { continue }

                if authorUri == InventoryModel.unkownAuthorId {
                    for work in workDTOs {
                        modelContext.insert(Work(entityDTO: work, authors: [], apiService: apiService))
                    }
                } else {
                    guard let authors: [Author] = try await getOrFetchAuthors(modelContext: modelContext, uris: [authorUri]) else { continue }
                    for work in workDTOs {
                        _ = authors.map { author in
                            author.works.append(Work(entityDTO: work, authors: authors, apiService: apiService))
                            modelContext.insert(author)
                        }
                    }
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
                        let myItem = InventoryItem(itemDTO: itemDTO, forUser: forUser, apiService: apiService)
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
            notes: "",
            transaction: transaction.rawValue,
            visibility: visibility.map { $0.rawValue },
            shelves: []
        )

        guard let itemDTO: ItemDTO = try await apiService.send(toEndpoint: "/api/items", payload: payload) else {
            throw NetworkError.badResponse
        }

        let newItem = InventoryItem(itemDTO: itemDTO, forUser: forUser, apiService: apiService)
        modelContext.insert(newItem)
        try modelContext.save()
        return newItem
    }

    func removeItem( _ item: InventoryItem, modelContext: ModelContext) async throws {
        let payload:[String:[String]] = ["ids":[item._id]]

        guard let ok: [String: Bool] = try await apiService.send(toEndpoint: "/api/items?action=delete-by-ids", payload: payload) else {
            throw NetworkError.badResponse
        }

        if let ok: Bool = ok["ok"], ok == true {
            modelContext.delete(item)
            try modelContext.save()
        }
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
                imageUrl: apiService.absoluteImageUrl(result.image),
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
        guard let works:[Work] = try? await getOrFetchWorks(modelContext: modelContext, uris: authorWorkDTO.map(\.uri)) else {
            return nil
        }

        for work in works {
            work.authors.append(author)
            modelContext.insert(work)
        }

        try modelContext.save()
        return works
    }

    func getWorkEditions(modelContext: ModelContext, work: Work) async throws -> [Edition]? {
        let endpoint = "/api/entities?action=reverse-claims&property=wdt:P629&value=\(work.uri)&refresh=false"
        let response: WorkEditionsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let editionUris = response?.uris else {return nil}

        guard let editions = try? await getOrFetchEditions(modelContext: modelContext, uris: editionUris ) else {
            return nil
        }

        for edition in editions {
            edition.works.append(work)
            modelContext.insert(edition)
        }

        try modelContext.save()
        return editions
    }

    func getOrFetchWorks(modelContext: ModelContext, uris: [String]) async throws -> [Work]? {

        var works: [Work] = []
        var urisToFetch: [String] = []
        for uri in uris {
            if let work = try? getLocalWork(modelContext: modelContext, uri: uri) {
                works.append(work)
            } else {
                urisToFetch.append(uri)
            }
        }

        guard let worksDto = try await fetchEntities(modelContext: modelContext, uri: urisToFetch) else {
            return nil
        }

        for workDto in worksDto {
            let authorUris: [String] = workDto.claims[WikidataProperty.author.rawValue]?
                .compactMap { $0.getStringValue() } ?? []
            let authors = try? await getOrFetchAuthors(modelContext: modelContext, uris: authorUris)

            let work = Work(entityDTO: workDto, authors: authors ?? [], apiService: apiService)
            modelContext.insert(work)
            works.append(work)
        }
        return  works
    }

    func getOrFetchWork(modelContext: ModelContext, uri: String) async throws -> Work? {
        return try await getOrFetchWorks(modelContext: modelContext, uris: [uri])?.first
    }

    func getOrFetchAuthors(modelContext: ModelContext, uris: [String]) async throws -> [Author]? {

        var authors: [Author] = []
        var urisToFetch: [String] = []
        for uri in uris {
            if let author = try? getLocalAuthor(modelContext: modelContext, uri: uri) {
                authors.append(author)
            } else {
                urisToFetch.append(uri)
            }
        }

        guard let authorsDto = try await fetchEntities(modelContext: modelContext, uri: urisToFetch, debug: true) else {
            return authors
        }

        authors.append(contentsOf: authorsDto.compactMap { authorDto in
            Author(entityDTO: authorDto, apiService: apiService)
        })

        return authors
    }

    func getOrFetchEditions(modelContext: ModelContext, uris: [String]) async throws -> [Edition]? {

        var editions: [Edition] = []
        var urisToFetch: [String] = []
        for uri in uris {
            if let edition = try? getLocalEdition(modelContext: modelContext, uri: uri) {
                editions.append(edition)
            } else {
                urisToFetch.append(uri)
            }
        }

        guard let editionsDto = try await fetchEntities(modelContext: modelContext, uri: urisToFetch) else {
            return editions
        }

        editions.append(contentsOf: editionsDto.compactMap { editionDto in
            Edition(entityDto: editionDto, apiService: apiService)
        })

        return editions
    }

    func getOrFetchExtract(forUri uri: String, modelContext: ModelContext) async throws -> WpExtract? {
        if let extract = try getLocalExtract(modelContext: modelContext, uri: uri), !extract.content.isEmpty {
            return extract
        } else {
            if let extractDto: ExtractDTO = try await fetchExtract(for: uri) {
                let extract = WpExtract(uri: uri, content: extractDto.extract, url: extractDto.url)
                modelContext.insert(extract)
                try modelContext.save()

                return extract
            } else {
                return nil
            }
        }
    }

    func getLocalExtract(modelContext: ModelContext, uri: String) throws -> WpExtract? {
        let predicate = #Predicate<WpExtract> { object in
            object.uri == uri
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchExtract(for uri: String) async throws -> ExtractDTO? {
        guard let summariesDTO: SummariesDTO = try? await apiService.fetchData(fromEndpoint: "/api/data?action=summaries&uri=\(uri)&langs=fr&refresh=false") else {
            return nil
        }
        guard let summary: SummaryDTO = summariesDTO.summaries.first(where: { $0.key == "frwiki" }) else {
            return nil
        }
        guard let sitelink: SitelinkDTO = summary.sitelink else {
            return nil
        }
        guard let extractDto: ExtractDTO = try? await apiService.fetchData(fromEndpoint: "/api/data?action=wp-extract&lang=fr&title=\(sitelink.title)") else {
            return nil
        }

        return extractDto
    }

    func getLocalEdition(modelContext: ModelContext, uri: String) throws -> Edition? {
        let predicate = #Predicate<Edition> { object in
            object.uri == uri
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func fetchEntities(modelContext: ModelContext, uri: [String], debug: Bool = false) async throws -> [EntityResultDTO]? {
            var results: [EntityResultDTO] = []

            for uriBatch in uri.splitInSubArrays(of: 50) {
                let entityUrl: String = "/api/entities?action=by-uris&uris=\(uriBatch.joined(separator: "|"))&attributes=info|labels|descriptions|claims|image&lang=fr"
                let resultsDto: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: entityUrl, debug: debug)

                results.append(contentsOf: resultsDto.map { Array($0.entities.values) } ?? [])
            }

            return results
        }

    func updateItemsTransaction(modelContext: ModelContext, items: [InventoryItem]) async throws -> Void {
        let response: UpdateItemsResponseDTO? = try await updateItems(ids: items.map(\._id), attribute: "transaction", value: items.first?.transaction.rawValue ?? "")

        if response?.ok == true {
            try modelContext.save()
        } else {
            throw NSError(domain: "Failed to update items", code: 0, userInfo: nil)
        }
    }

    func updateItemsDetails(modelContext: ModelContext, items: [InventoryItem]) async throws -> Void {
        let response: UpdateItemsResponseDTO? = try await updateItems(ids: items.map(\._id), attribute: "details", value: items.first?.details ?? "")

        if response?.ok == true {
            try modelContext.save()
        } else {
            throw NSError(domain: "Failed to update items", code: 0, userInfo: nil)
        }
    }

    func updateItems(ids: [String], attribute: String, value: String?) async throws -> UpdateItemsResponseDTO? {

        return try await apiService.send(
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
