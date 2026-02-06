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
        let _: DeleteListResponseDTO? = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=delete",
            method: "POST",
            payload: ["ids": list._id]
        )
        modelContext.delete(list)
        try modelContext.save()
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

    func addEntitiesToList(listId: String, entityUris: [String]) async throws {
        let addToListDTO: AddToListDTO = .init(id: listId, uris: entityUris)
        let _: AddToListResponseDTO? = try await fetchDataService.send(
            toEndpoint: "/api/lists?action=add-elements",
            payload: addToListDTO,
            debug: true
        )
    }

//    Add elements to list
//    /api/lists?action=add-elements
//    {id: "049a5d616589c7d82d7e3ca3e0a1fd18", uris: ["wd:Q41663451"]}

//    Comment on list element
//    /api/lists?action=update-element
//    { "id": "313e939fbdbc1b5b545f0ad4f9298570", "comment": "Romans philosophique très chouette !" }

//    Search elements
//    /api/search?types=works|series&search=l%27espace%20d%27&lang=fr&limit=10&offset=0&exact=false
//    {
//        "results": [
//            {
//                "id": "Q1198588",
//                "type": "series",
//                "uri": "wd:Q1198588",
//                "label": "Odyssées de l'espace",
//                "description": "série de science-fiction",
//                "image": "/img/entities/be645f39a0898f9966f54994c06b48c13c28b5af",
//                "claims": {},
//                "_score": 4122.6904,
//                "_popularity": 144
//            },
//            {
//                "id": "Q41663451",
//                "type": "works",
//                "uri": "wd:Q41663451",
//                "label": "L'Espace d'un an",
//                "description": "roman de Becky Chambers",
//                "image": "/img/entities/acdbf01907e8ecc8fc2846b434115f14320f4078",
//                "claims": {},
//                "_score": 2823.6528,
//                "_popularity": 47
//            },
}
