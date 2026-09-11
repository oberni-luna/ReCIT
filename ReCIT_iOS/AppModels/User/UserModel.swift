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
final class UserModel {

    private let apiService: APIServicing
    var myUser: User?

    init(apiService: APIServicing) {
        self.apiService = apiService
    }

    func syncMyUser(modelContext: ModelContext) async throws {
        let userDTO: UserDTO? = try await apiService.fetchData(fromEndpoint: "/api/user")
        if let userDTO {
            let mySyncedUser = User(userDTO: userDTO, baseUrl: apiService.baseUrl())
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

        let usersDTO: UsersDTO? = try await apiService.fetchData(fromEndpoint: "/api/users/by-ids?ids=\(ids)")

        guard let usersDTO = usersDTO?.users, !usersDTO.isEmpty else { return [] }

        var users: [User] = []
        for userDTO in usersDTO {
            let otherUser = User(userDTO: userDTO.value, baseUrl: apiService.baseUrl())
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

        let userNetwork: UserNetworkDTO? = try await apiService.fetchData(fromEndpoint: "/api/relations")
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
        guard let myUser else { return }
        self.myUser = nil
        modelContext.delete(myUser)
        try modelContext.save()
    }

    func logout(modelContext: ModelContext) throws {
        try clearUserData(modelContext: modelContext)
    }

    /// Deletes the account on inventaire.io, then leaves this device with nothing of it.
    ///
    /// **Server first, always.** The local wipe runs only after the server has answered `ok`:
    /// an app that erased its copy on a failed call would leave the user believing an account
    /// is gone while it is still live on inventaire.io — the one lie this screen cannot afford.
    /// A failure therefore throws with the store untouched, and the caller says so.
    ///
    /// **What the server does with it** (`server/controllers/user/delete.ts`): the user document
    /// is soft-deleted — only `_id`, `_rev`, `created`, `username`, `stableUsername` and
    /// `anonymizableId` survive, so the username stays taken — and the relations, group
    /// memberships, active transactions, notifications, shelves, listings and items all go. It
    /// then closes the session itself, which is why the caller pairs this with
    /// `AuthModel.forgetSession()` rather than a logout.
    ///
    /// **Why the whole store, and not just this user's rows.** The account that owned this
    /// device's cache no longer exists, and every row here was fetched under it: friends and
    /// their inventories, the entities their books point at, the étagères and the lists. Left
    /// in place they would surface under the *next* account signed in on this phone, which is
    /// not a stale cache but someone else's data on the wrong screen.
    func deleteAccount(modelContext: ModelContext) async throws {
        guard let response: OkStatusDTO = try await apiService.send(
            toEndpoint: "/api/user",
            method: "DELETE"
        ), response.ok else {
            throw NetworkError.badResponse
        }

        myUser = nil
        try wipeLocalStore(modelContext: modelContext)
    }

    /// Empties every model in the container's schema, in one save.
    ///
    /// Spelled out type by type rather than looped: the list is the only thing that fails loudly
    /// when a new `@Model` is added to `ReCIT.makeModelContainer` and forgotten here — a silent
    /// survivor would be the bug. Owned rows come first, then the entities they point at, then
    /// the users that own them, so nothing is deleted out from under a relationship.
    ///
    /// **Fetched and deleted one by one, not `delete(model:)`.** The batch form skips the object
    /// graph, and `InventoryItem.edition` is a mandatory to-one: SwiftData answers a batch delete
    /// with `Constraint trigger violation: Batch delete failed due to mandatory OTO nullify
    /// inverse on InventoryItem/edition` and nothing is deleted at all. Per-object deletion runs
    /// the relationship rules, which is what a store of this shape needs.
    private func wipeLocalStore(modelContext: ModelContext) throws {
        try deleteAll(InventoryItem.self, in: modelContext)
        try deleteAll(Shelf.self, in: modelContext)
        try deleteAll(EntityListItem.self, in: modelContext)
        try deleteAll(EntityList.self, in: modelContext)
        try deleteAll(TransactionMessage.self, in: modelContext)
        try deleteAll(UserTransaction.self, in: modelContext)
        try deleteAll(WpExtract.self, in: modelContext)
        try deleteAll(Edition.self, in: modelContext)
        try deleteAll(Work.self, in: modelContext)
        try deleteAll(Author.self, in: modelContext)
        try deleteAll(User.self, in: modelContext)
        try modelContext.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type, in modelContext: ModelContext) throws {
        for object in try modelContext.fetch(FetchDescriptor<T>()) {
            modelContext.delete(object)
        }
    }

}
