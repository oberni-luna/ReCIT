//
//  AppModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 21/08/2025.
//

import Foundation
import Combine
import SwiftData

class UserModel: ObservableObject {

    private let fetchDataService: APIService
    @Published var myUser: User?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.fetchDataService = fetchDataService
    }

    func syncUser(modelContext: ModelContext) async throws {
        let userDTO: UserDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/user")
        if let userDTO {
            let mySyncedUser = User(userDTO: userDTO)
            modelContext.insert(mySyncedUser)
            self.myUser = mySyncedUser
        } else {
            throw NetworkError.badResponse
        }
    }

//    Add elements to list
//    /api/lists?action=add-elements
//    {id: "049a5d616589c7d82d7e3ca3e0a1fd18", uris: ["wd:Q41663451"]}

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
