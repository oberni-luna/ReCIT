//
//  EntityModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftData
import Foundation
import Combine

class EntityModel: ObservableObject {
    private let apiService: APIService

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    // MARK: - Authors

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

        guard let authorsDto = try await fetchEntities(modelContext: modelContext, uris: urisToFetch, debug: true) else {
            return authors
        }

        authors.append(contentsOf: authorsDto.compactMap { authorDto in
            let author: Author = .init(entityDTO: authorDto, apiService: apiService)
            modelContext.insert(author)
            return author
        })
        try modelContext.save()

        return authors
    }

    func getAuthorWorks(modelContext: ModelContext, author: Author) async throws -> [Work]? {
        let endpoint: String = "/api/entities?action=author-works&uri=\(author.uri)&refresh=false"
        let response: AuthorWorksDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let authorWorkDTO = response?.works else { return nil }
        guard let works: [Work] = try? await getOrFetchWorks(modelContext: modelContext, uris: authorWorkDTO.map(\.uri)) else {
            return nil
        }

        for work in works {
            work.authors.append(author)
            modelContext.insert(work)
        }

        try modelContext.save()
        return works
    }

    // MARK: - Works

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

        guard let worksDto = try await fetchEntities(modelContext: modelContext, uris: urisToFetch) else {
            return nil
        }

        for workDto in worksDto {
            let authorUris: [String] = workDto.claims[WikidataProperty.author.rawValue]?
                .compactMap { $0.getStringValue() } ?? []
            let authors: [Author] = (try? await getOrFetchAuthors(modelContext: modelContext, uris: authorUris)) ?? []

            let work: Work = .init(entityDTO: workDto, authors: authors, apiService: apiService)
            modelContext.insert(work)
            works.append(work)
        }
        return works
    }

    func getOrFetchWork(modelContext: ModelContext, uri: String) async throws -> Work? {
        try await getOrFetchWorks(modelContext: modelContext, uris: [uri])?.first
    }

    func getWorkEditions(modelContext: ModelContext, work: Work) async throws -> [Edition]? {
        let endpoint: String = "/api/entities?action=reverse-claims&property=wdt:P629&value=\(work.uri)&refresh=false"
        let response: WorkEditionsDTO? = try await apiService.fetchData(fromEndpoint: endpoint)

        guard let editionUris = response?.uris else { return nil }
        guard let editions = try? await getOrFetchEditions(modelContext: modelContext, uris: editionUris) else {
            return nil
        }

        for edition in editions {
            edition.works.append(work)
            modelContext.insert(edition)
        }

        try modelContext.save()
        return editions
    }

    // MARK: - Editions

    func getOrFetchEditions(modelContext: ModelContext, uris: [String]) async throws -> [Edition]? {
        var editions: [Edition] = []
        var urisToFetch: [String] = []
        var editionsNeedingWorks: [Edition] = []

        for uri in uris {
            if let edition = try? getLocalEdition(modelContext: modelContext, uri: uri) {
                editions.append(edition)
                if edition.works.isEmpty {
                    editionsNeedingWorks.append(edition)
                }
            } else {
                urisToFetch.append(uri)
            }
        }

        // Fetch new editions from the API and resolve their works and authors
        if let editionsDto = try await fetchEntities(modelContext: modelContext, uris: urisToFetch) {
            for editionDto in editionsDto {
                let edition: Edition = .init(entityDto: editionDto, apiService: apiService)
                edition.works = try await resolveEditionWorks(
                    from: editionDto,
                    modelContext: modelContext
                )
                modelContext.insert(edition)
                editions.append(edition)
            }
        }

        // Resolve works for local editions that don't have any yet
        if !editionsNeedingWorks.isEmpty {
            let urisToRefetch: [String] = editionsNeedingWorks.map(\.uri)
            if let editionDtos = try await fetchEntities(modelContext: modelContext, uris: urisToRefetch) {
                for editionDto in editionDtos {
                    guard let edition = editionsNeedingWorks.first(where: { $0.uri == editionDto.uri }) else { continue }
                    edition.works = try await resolveEditionWorks(
                        from: editionDto,
                        modelContext: modelContext
                    )
                }
            }
        }

        try modelContext.save()
        return editions
    }

    func getLocalEdition(modelContext: ModelContext, uri: String) throws -> Edition? {
        let predicate: Predicate<Edition> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Edition> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Extracts

    func getOrFetchExtract(forUri uri: String, modelContext: ModelContext) async throws -> WpExtract? {
        if let extract = try getLocalExtract(modelContext: modelContext, uri: uri), !extract.content.isEmpty {
            return extract
        }

        if let extractDto: ExtractDTO = try await fetchExtract(for: uri) {
            let extract: WpExtract = .init(uri: uri, content: extractDto.extract, url: extractDto.url)
            modelContext.insert(extract)
            try modelContext.save()
            return extract
        }

        return nil
    }

    func getLocalExtract(modelContext: ModelContext, uri: String) throws -> WpExtract? {
        let predicate: Predicate<WpExtract> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<WpExtract> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchExtract(for uri: String) async throws -> ExtractDTO? {
        guard let summariesDTO: SummariesDTO = try? await apiService.fetchData(
            fromEndpoint: "/api/data?action=summaries&uri=\(uri)&langs=fr&refresh=false"
        ) else {
            return nil
        }

        if let summary: SummaryDTO = summariesDTO.summaries.first(where: {
            $0.key == WikidataProperty.summary.rawValue && $0.lang == "fr"
        }) {
            return .init(extract: summary.text ?? "", url: summary.link)
        } else if let summary: SummaryDTO = summariesDTO.summaries.first(where: { $0.key == "frwiki" }) {
            guard let sitelink: SitelinkDTO = summary.sitelink else { return nil }
            return try? await apiService.fetchData(
                fromEndpoint: "/api/data?action=wp-extract&lang=fr&title=\(sitelink.title)"
            )
        }

        return nil
    }

    // MARK: - Private helpers

    /// Extracts work URIs from an edition DTO's claims and fetches the associated works and their authors.
    private func resolveEditionWorks(
        from editionDto: EntityResultDTO,
        modelContext: ModelContext
    ) async throws -> [Work] {
        let workUris: [String] = editionDto.claims[WikidataProperty.editionOf.rawValue]?
            .compactMap { $0.getStringValue() } ?? []

        guard !workUris.isEmpty else { return [] }

        return (try? await getOrFetchWorks(modelContext: modelContext, uris: workUris)) ?? []
    }

    func fetchEntities(modelContext: ModelContext, uris: [String], debug: Bool = false) async throws -> [EntityResultDTO]? {
        var results: [EntityResultDTO] = []

        for uriBatch in uris.splitInSubArrays(of: 50) {
            let entityUrl: String = "/api/entities?action=by-uris&uris=\(uriBatch.joined(separator: "|"))&attributes=info|labels|descriptions|claims|image&lang=fr"
            let resultsDto: EntityResultsDTO? = try await apiService.fetchData(fromEndpoint: entityUrl, debug: debug)
            results.append(contentsOf: resultsDto.map { Array($0.entities.values) } ?? [])
        }

        return results
    }

    func getLocalWork(modelContext: ModelContext, uri: String) throws -> Work? {
        let predicate: Predicate<Work> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Work> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func getLocalAuthor(modelContext: ModelContext, uri: String) throws -> Author? {
        let predicate: Predicate<Author> = #Predicate { object in
            object.uri == uri
        }
        let descriptor: FetchDescriptor<Author> = .init(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}
