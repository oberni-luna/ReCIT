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

    func syncMyUser(modelContext: ModelContext) async throws {
        let userDTO: UserDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/user")
        if let userDTO {
            let mySyncedUser = User(userDTO: userDTO, baseUrl: fetchDataService.baseUrl())
            modelContext.insert(mySyncedUser)
            try modelContext.save()

            if let user = try getLocalUser(modelContext: modelContext, _id: mySyncedUser._id) {
                self.myUser = user
            }

        } else {
            throw NetworkError.badResponse
        }
    }

    private func getLocalUser(modelContext: ModelContext, _id: String) throws -> User? {
        let predicate = #Predicate<User> { object in
            object._id == _id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func syncOtherUser(modelContext: ModelContext, userIds: [String]) async throws {
        let ids = userIds.joined(separator: "|")
        guard ids.isEmpty == false else { return }

        let usersDTO: UsersDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/users?action=by-ids&ids=\(ids)")

        guard let users = usersDTO?.users, !users.isEmpty else { return }

        for user in users {
            let otherUser = User(userDTO: user.value, baseUrl: fetchDataService.baseUrl())
            modelContext.insert(otherUser)
        }
    }

    func syncUserNetwork(modelContext: ModelContext) async throws {
        guard let myUser else { return }

        let userNetwork: UserNetworkDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/relations")
        guard let userNetwork else { return }
        
        let userIds = Array(Set(userNetwork.network).filter { $0 != myUser._id })
        if userIds.isEmpty { return }
        
        try await syncOtherUser(modelContext: modelContext, userIds: userIds)
    }

    func getAllOtherUsers(modelContext: ModelContext) -> [User] {
        do {
            let data = try modelContext.fetch(FetchDescriptor<User>())
            return data.filter { $0._id != myUser?._id }
        } catch {
            return []
        }
    }

    func clearUserData(modelContext: ModelContext) async throws {
        if let myUser {
            do {
                modelContext.delete(myUser)
                try modelContext.save()
            } catch {
                print("Failed to delete user related content")
            }
        }
    }

    func logout(modelContext: ModelContext) async throws {
        do {
            try await clearUserData(modelContext: modelContext)
        } catch {
            print("Failed to delete user related content")
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
