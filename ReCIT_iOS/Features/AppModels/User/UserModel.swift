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
            let user = try getLocalUser(modelContext: modelContext, _id: mySyncedUser._id)

            if let user {
                user.update(with: mySyncedUser)
                myUser = user
            } else {
                modelContext.insert(mySyncedUser)
                myUser = mySyncedUser
            }

            try modelContext.save()
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

    func getOrFetchUsers(modelContext: ModelContext, userIds: [String]) async throws -> [User] {
        let ids = userIds.joined(separator: "|")
        guard ids.isEmpty == false else { return [] }

        let usersDTO: UsersDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/users?action=by-ids&ids=\(ids)")

        guard let usersDTO = usersDTO?.users, !usersDTO.isEmpty else { return [] }

        var users: [User] = []
        for userDTO in usersDTO {
            let otherUser = User(userDTO: userDTO.value, baseUrl: fetchDataService.baseUrl())
            if let user = try getLocalUser(modelContext: modelContext, _id: otherUser._id) {
                user.update(with: otherUser)
                users.append(user)
            } else {
                modelContext.insert(otherUser)
                users.append(otherUser)
            }
        }
        try modelContext.save()

        return users
    }

    func syncUserNetwork(modelContext: ModelContext) async throws {
        guard let myUser else { return }

        let userNetwork: UserNetworkDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/relations")
        guard let userNetwork else { return }
        
        let userIds = Array(Set(userNetwork.network).filter { $0 != myUser._id })
        if userIds.isEmpty { return }
        
        _ = try await getOrFetchUsers(modelContext: modelContext, userIds: userIds)
    }

    func getAllOtherUsers(modelContext: ModelContext) -> [User] {
        do {
            let data = try modelContext.fetch(FetchDescriptor<User>())
            return data.filter { $0._id != myUser?._id }
        } catch {
            return []
        }
    }

    func clearUserData(modelContext: ModelContext) throws {
        if let myUser {
            do {
                modelContext.delete(myUser)
                try modelContext.save()
            } catch {
                print("Failed to delete user related content")
            }
        }
    }

    func logout(modelContext: ModelContext) throws {
        do {
            try clearUserData(modelContext: modelContext)
        } catch {
            print("Failed to delete user related content")
        }
    }

}
