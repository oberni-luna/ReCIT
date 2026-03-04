//
//  AppModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import Combine
import SwiftData

class ListModel: ObservableObject {

    private let fetchDataService: APIService
    @Published var myUser: User?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.fetchDataService = fetchDataService
    }

    func syncLists(forUser: User, modelContext: ModelContext) async throws {
        try modelContext.delete(model: EntityList.self)
        let listsDTO: ListsDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/lists?action=by-creators&users=\(forUser._id)&with-elements=true", debug: true)
        if let listsDTO {
            for listDTO in listsDTO.lists {
                let list = EntityList(listDTO: listDTO, baseUrl: fetchDataService.baseUrl())
                modelContext.insert(list)
            }
            try modelContext.save()
        }
    }

    func deleteList(modelContext: ModelContext, list: EntityList) async throws {
        if let _: OkStatusDTO? = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=delete",
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
            let _ : NewListResponseDTO? = try await fetchDataService.send(
                toEndpoint: "/api/lists",
                method: "PUT",
                payload: NewListDTO(id: list._id, name: list.name, description: list.explanation, visibility: list.visibility.map(\.rawValue), type: nil),
                debug: true
            )
            try modelContext.save()
        }
    }

    func createList(modelContext: ModelContext, name: String, description: String, type: String, visibility: [String]) async throws {
        let newList: NewListResponseDTO? = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=create",
            payload: NewListDTO(id: nil, name: name, description: description, visibility: visibility, type: type)
        )

        if let newList {
            modelContext.insert(EntityList(listDTO: newList.list, baseUrl: fetchDataService.baseUrl()))
            try modelContext.save()
        }
    }

    // TODO: add optionnal comment when adding an element to a list 
    func addEntitiesToList(modelContext: ModelContext, list: EntityList, entityUris: [String], comment: String? = nil) async throws {
        let addToListDTO: AddToListDTO = .init(id: list._id, uris: entityUris)
        if let addToListResponseDTO : AddToListResponseDTO = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=add-elements",
            payload: addToListDTO,
            debug: true
        ) {
            for element in addToListResponseDTO.createdElements {
                if let comment, comment.isEmpty == false {
                    let _:ListElementDTO? = try await updateElementInList(elementId: element._id, comment: comment)
                }

                let entityListItem: EntityListItem = .init(listElementDTO: element, listType: list.type, baseUrl: fetchDataService.baseUrl())
                modelContext.insert(entityListItem)
            }
            try modelContext.save()
        }
    }

    // TODO: Implement remove item from list
//    {id: "97e848f4af0a5ffe2886648ee2bc648b", uris: ["inv:fd0bbd368cb02d614a3b29857f960fbe"]}
    func deleteElementsInList(modelContext: ModelContext,listId: String, elementIds: [String]) async throws {
        let payload: DeleteListElementsDTO = .init(id: listId, uris: elementIds)

        if let listResponseDTO : [String: ListDTO] = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=remove-elements",
            payload: payload,
            debug: true
        ),
        let listDTO = listResponseDTO["list"] {
            let list = EntityList(listDTO: listDTO, baseUrl: fetchDataService.baseUrl())
            modelContext.insert(list)
        }
        try modelContext.save()
    }

    // TODO: Implement update item in a list to add comment
    // TODO: add optionnal comment when adding an element to a list
    func updateElementInList(elementId: String, comment: String) async throws -> ListElementDTO? {
        let updateListElementDTO: UpdateListElementDTO = .init(id: elementId, comment: comment)
        let elementDto: ListElementDTO? = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=update-element",
            payload: updateListElementDTO,
            debug: true
        )

        return elementDto
    }

}
