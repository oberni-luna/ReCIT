//
//  AppModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ListModel: OptimisticMutating {

    private let apiService: APIServicing

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Most recent optimistic background task, exposed so tests can await it.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    func syncLists(forUser: User, modelContext: ModelContext) async throws {
        let listsDTO: ListsDTO? = try await apiService.fetchData(fromEndpoint: "/api/lists/by-creators?users=\(forUser._id)&with-elements=true", debug: true)
        guard let listsDTO else { return }

        let baseUrl: String = apiService.baseUrl()
        // Upsert in place (never delete+reinsert) so any open list view stays reactive.
        try modelContext.upsert(
            listsDTO.lists,
            dtoID: { $0._id },
            modelID: { (list: EntityList) in list._id },
            make: { EntityList(listDTO: $0, baseUrl: baseUrl) },
            update: { list, dto in list.update(listDTO: dto, baseUrl: baseUrl, modelContext: modelContext) },
            deleteMissing: true
        )
        try modelContext.save()
    }

    func deleteList(modelContext: ModelContext, list: EntityList) async throws {
        if let _: OkStatusDTO? = try await apiService.send(
            toEndpoint: "/api/lists/delete",
            method: "POST",
            payload: ["ids": list._id]
        ) {
            modelContext.delete(list)
            try modelContext.save()
        }
    }

    func createOrUpdateList(modelContext: ModelContext, list: EntityList) async throws {
        if list._id.isEmpty {
            try await self.createList(modelContext: modelContext, name: list.name, description: list.explanation, type: list.type.rawValue, visibility: list.visibility.map(\.rawValue))
        } else {
            let _ : NewListResponseDTO? = try await apiService.send(
                toEndpoint: "/api/lists",
                method: "PUT",
                payload: NewListDTO(id: list._id, name: list.name, description: list.explanation, visibility: list.visibility.map(\.rawValue), type: nil),
                debug: true
            )
            try modelContext.save()
        }
    }

    /// Creates a list server-side and inserts the list the server answers with.
    ///
    /// - Returns: the inserted list, carrying its **server** id — which is what lets a caller
    ///   chain a second write onto it. An answerless response throws rather than returning
    ///   nothing: a caller that goes on to file something into the list would otherwise have no
    ///   way of knowing there is no list to file into.
    @discardableResult
    func createList(modelContext: ModelContext, name: String, description: String, type: String, visibility: [String]) async throws -> EntityList {
        let newList: NewListResponseDTO? = try await apiService.send(
            toEndpoint: "/api/lists",
            payload: NewListDTO(id: nil, name: name, description: description, visibility: visibility, type: type)
        )

        guard let newList else { throw NetworkError.badResponse }

        let list: EntityList = .init(listDTO: newList.list, baseUrl: apiService.baseUrl())
        modelContext.insert(list)
        try modelContext.save()
        return list
    }

    /// Creates a list and files a work into it — the « Ajouter à une nouvelle liste » line of
    /// the "…" menus (PRD 0014). The order of the two calls, and the difference of optimism
    /// between them, live here and nowhere else: the form calls this and knows neither.
    ///
    /// Creation is **awaited**, because filing needs the list's server id and must never post
    /// toward an optimistic one. Filing is then **optimistic**, as it is everywhere else: if it
    /// fails, it undoes itself and reports through the shared channel — the list stays. A
    /// container the user has watched being born is never destroyed to make up for a second
    /// request that failed.
    ///
    /// The type is not a parameter: a list made to hold a book's work is a works list.
    ///
    /// - Throws: only what creation throws, so a failing creation leaves nothing behind and
    ///   lets the caller keep its sheet open.
    /// - Returns: the created list, so the caller can name it back to the user.
    @discardableResult
    func createListAndAddWork(
        modelContext: ModelContext,
        name: String,
        description: String,
        visibility: [String],
        workUri: String
    ) async throws -> EntityList {
        let list: EntityList = try await createList(
            modelContext: modelContext,
            name: name,
            description: description,
            type: EntityListType.work.rawValue,
            visibility: visibility
        )

        addEntitiesToList(
            modelContext: modelContext,
            list: list,
            entityUris: [workUri]
        )

        return list
    }

    /// Optimistically adds entities to a list: placeholders appear immediately,
    /// the server call runs in the background, and on success the placeholders are
    /// swapped for the server's canonical elements (real `_id`s). On failure the
    /// placeholders are removed and the error is surfaced.
    func addEntitiesToList(modelContext: ModelContext, list: EntityList, entityUris: [String], comment: String? = nil) {
        let baseUrl: String = apiService.baseUrl()
        let placeholders: [EntityListItem] = entityUris.map { uri in
            .init(_id: OptimisticID.make(), comment: comment ?? "", uri: uri, ordinal: "0", created: .now, itemType: list.type)
        }

        inFlightTask = optimistic(
            modelContext,
            apply: {
                for placeholder in placeholders {
                    modelContext.insert(placeholder)
                    list.elements.append(placeholder)
                }
            },
            revert: {
                for placeholder in placeholders {
                    list.elements.removeAll { $0._id == placeholder._id }
                    modelContext.delete(placeholder)
                }
            },
            request: { [weak self] in
                guard let self else { return }
                let payload: AddToListDTO = .init(id: list._id, uris: entityUris)
                guard let response: AddToListResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/lists/add-elements",
                    method: "PUT",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }

                // Reconcile: drop placeholders, insert the server's canonical elements.
                for placeholder in placeholders {
                    list.elements.removeAll { $0._id == placeholder._id }
                    modelContext.delete(placeholder)
                }
                for element in response.createdElements {
                    if let comment, comment.isEmpty == false {
                        _ = try await self.updateElementInList(elementId: element._id, comment: comment)
                    }
                    let item: EntityListItem = .init(listElementDTO: element, listType: list.type, baseUrl: baseUrl)
                    modelContext.insert(item)
                    list.elements.append(item)
                }
            }
        )
    }

    // TODO: Implement remove item from list
//    {id: "97e848f4af0a5ffe2886648ee2bc648b", uris: ["inv:fd0bbd368cb02d614a3b29857f960fbe"]}
    func deleteElementsInList(modelContext: ModelContext, listId: String, elementIds: [String]) async throws {
        let payload: DeleteListElementsDTO = .init(id: listId, uris: elementIds)

        if let listResponseDTO: [String: ListDTO] = try await apiService.send(
            toEndpoint: "/api/lists/remove-elements",
            method: "PUT",
            payload: payload,
            debug: true
        ),
        listResponseDTO["list"] != nil {
            let descriptor: FetchDescriptor<EntityListItem> = .init(
                predicate: #Predicate<EntityListItem> { item in
                    item.list?._id == listId && elementIds.contains(item.uri)
                }
            )
            if let items = try? modelContext.fetch(descriptor) {
                for item in items {
                    modelContext.delete(item)
                }
            }
            try modelContext.save()
        }
    }

    // TODO: Implement update item in a list to add comment
    // TODO: add optionnal comment when adding an element to a list
    func updateElementInList(elementId: String, comment: String) async throws -> ListElementDTO? {
        let updateListElementDTO: UpdateListElementDTO = .init(id: elementId, comment: comment)
        let elementDto: ListElementDTO? = try await apiService.send(
            toEndpoint: "/api/lists/update-element",
            method: "PUT",
            payload: updateListElementDTO,
            debug: true
        )

        return elementDto
    }

}
