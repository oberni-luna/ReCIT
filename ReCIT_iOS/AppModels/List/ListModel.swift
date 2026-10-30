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

    /// Syncs **my** lists. The lists stored before `EntityList.creatorId` existed are mine too,
    /// so this sync is the one allowed to prune them.
    func syncLists(forUser: User, modelContext: ModelContext) async throws {
        try await syncLists(createdBy: forUser._id, claimsUnstamped: true, modelContext: modelContext)
    }

    /// Syncs the lists a friend lets me see, for their profile. The server applies the
    /// visibility; nothing is filtered here.
    func syncFriendLists(of user: User, modelContext: ModelContext) async throws {
        try await syncLists(createdBy: user._id, claimsUnstamped: false, modelContext: modelContext)
    }

    /// The answer holds one reader's lists and nobody else's, so the deletion pass is scoped to
    /// that reader: without it, opening a friend's profile would delete every list of mine.
    private func syncLists(createdBy creatorId: String, claimsUnstamped: Bool, modelContext: ModelContext) async throws {
        let listsDTO: ListsDTO? = try await apiService.fetchData(fromEndpoint: "/api/lists/by-creators?users=\(creatorId)&with-elements=true", debug: true)
        guard let listsDTO else { return }

        let baseUrl: String = apiService.baseUrl()
        // Upsert in place (never delete+reinsert) so any open list view stays reactive.
        let synced: [EntityList] = try modelContext.upsert(
            listsDTO.lists,
            dtoID: { $0._id },
            modelID: { (list: EntityList) in list._id },
            make: { EntityList(listDTO: $0, baseUrl: baseUrl) },
            update: { list, dto in list.update(listDTO: dto, baseUrl: baseUrl, modelContext: modelContext) },
            deleteMissing: true,
            scope: { list in
                list.creatorId == creatorId || (claimsUnstamped && list.creatorId == nil)
            }
        )
        // Stamped from the request when the answer does not say: these are the creator's lists.
        for list in synced where list.creatorId == nil {
            list.creatorId = creatorId
        }
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
            subjects: [list],
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

    /// Moves an element into another list, with its comment — « Déplacer dans une autre liste ».
    ///
    /// **Server-first, not optimistic**, in three calls that each wait for the one before: add the
    /// uri to `destination`, write the comment on the element just created, take the uri out of
    /// `source`. A failure stops the rest, so the element is never taken out of a list before it
    /// has landed in the other; at worst it is in both. Whatever did land on the server is in the
    /// store before the error is thrown, so the screen shows what the server holds.
    ///
    /// A destination that already holds the uri creates nothing (`alreadyInList`): the element is
    /// then only taken out of `source`, and the destination keeps its own comment.
    func moveElement(
        modelContext: ModelContext,
        item: EntityListItem,
        from source: EntityList,
        to destination: EntityList
    ) async throws {
        let uri: String = item.uri
        let comment: String = item.comment
        let sourceId: String = source._id

        guard let response: AddToListResponseDTO = try await apiService.send(
            toEndpoint: "/api/lists/add-elements",
            method: "PUT",
            payload: AddToListDTO(id: destination._id, uris: [uri]),
            debug: true
        ) else {
            throw NetworkError.badResponse
        }

        var landed: [ListElementDTO] = response.createdElements
        do {
            if comment.isEmpty == false, let element = landed.first {
                guard let commented = try await updateElementInList(elementId: element._id, comment: comment) else {
                    throw NetworkError.badResponse
                }
                landed = [commented]
            }
        } catch {
            try file(landed, into: destination, modelContext: modelContext)
            throw error
        }
        try file(landed, into: destination, modelContext: modelContext)

        try await deleteElementsInList(
            modelContext: modelContext,
            listId: sourceId,
            elementIds: [uri]
        )
    }

    /// Inserts elements the server has created into a list of the store, unless the list has left
    /// it during the round trip or already holds them.
    private func file(_ elements: [ListElementDTO], into list: EntityList, modelContext: ModelContext) throws {
        guard list.isStillInTheStore else { return }

        let baseUrl: String = apiService.baseUrl()
        let heldIDs: Set<String> = .init(list.elements.map(\._id))
        for element in elements where heldIDs.contains(element._id) == false {
            let item: EntityListItem = .init(listElementDTO: element, listType: list.type, baseUrl: baseUrl)
            modelContext.insert(item)
            list.elements.append(item)
        }
        try modelContext.save()
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

    /// Optimistically writes the reader's comment on an element: the store holds the new text at
    /// once, `/api/lists/update-element` is called in the background, and a failure puts the
    /// previous text back and is surfaced through the shared channel (ADR 0001).
    ///
    /// Nothing is sent when the text has not changed, nor for an element still carrying its
    /// optimistic id: the server does not know that id yet, and the field that calls this is
    /// disabled until the add has been reconciled.
    func updateComment(modelContext: ModelContext, item: EntityListItem, comment: String) {
        let previous: String = item.comment
        let elementId: String = item._id
        guard comment != previous, OptimisticID.isOptimistic(elementId) == false else { return }

        inFlightTask = optimistic(
            modelContext,
            subjects: [item],
            apply: {
                item.comment = comment
            },
            revert: {
                item.comment = previous
            },
            request: { [weak self] in
                guard let self else { return }
                guard try await self.updateElementInList(elementId: elementId, comment: comment) != nil else {
                    throw NetworkError.badResponse
                }
            }
        )
    }

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
