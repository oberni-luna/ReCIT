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
final class UserModel: OptimisticMutating {

    private let apiService: APIServicing
    var myUser: User?

    /// Shared channel used to surface a background optimistic failure to the UI.
    var errorReporter: AppErrorReporter?

    /// The most recent background task spawned by an optimistic relation write. Exposed so
    /// tests can await completion; not observed by the UI.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
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

    /// Reads `GET /api/relations` and writes the four states it answers onto the store.
    ///
    /// One call carries everything: `friends`, `userRequested`, `otherRequested` and `network`.
    /// Until issue 0083 only `network` was kept, so the app fetched the users but knew nothing
    /// of where it stood with any of them — the whole add-a-friend flow lives in the three
    /// lists that were being dropped.
    ///
    /// The write is exhaustive, not incremental: every stored user that the answer does not
    /// name falls back to `.none`. That is what makes a relation undone elsewhere — on the
    /// website, or by the other side refusing — disappear here, instead of surviving as a
    /// friend nobody can see any more.
    func syncRelations(modelContext: ModelContext) async throws {
        guard let myUser else { return }

        let userNetwork: UserNetworkDTO? = try await apiService.fetchData(fromEndpoint: "/api/relations")
        guard let userNetwork else { return }

        let states: [String: UserRelation] = UserRelation.byUserID(from: userNetwork)
        let userIds: [String] = Array(Set(userNetwork.network + Array(states.keys))).filter { $0 != myUser._id }
        if userIds.isEmpty == false {
            _ = try await getOrFetchUsers(modelContext: modelContext, userIds: userIds)
        }

        for user in try modelContext.fetch(FetchDescriptor<User>()) where user._id != myUser._id {
            user.relation = states[user._id] ?? .none
        }
        myUser.relation = .none

        try modelContext.save()
    }

    // MARK: - Relation writes

    /// Asks to join `user`'s network. Optimistic: the row says « envoyée » before the server
    /// has answered, and goes back to what it was if the call fails (ADR 0001).
    ///
    /// No message travels with it — `POST /api/relations/request` takes a user id and nothing
    /// else, which is why the sheet that raises this only confirms.
    func requestRelation(with user: User, modelContext: ModelContext) {
        changeRelation(user, to: .requestSent, action: "request", modelContext: modelContext)
    }

    /// Takes back a request I sent. The other side never learns it existed.
    func cancelRelation(with user: User, modelContext: ModelContext) {
        changeRelation(user, to: .none, action: "cancel", modelContext: modelContext)
    }

    /// The shape shared by every relation write: one local state change, one POST carrying the
    /// user id, and the previous state put back if the server refuses.
    private func changeRelation(
        _ user: User,
        to newRelation: UserRelation,
        action: String,
        modelContext: ModelContext
    ) {
        let previousRelation: UserRelation = user.relation
        let userId: String = user._id

        inFlightTask = optimistic(
            modelContext,
            apply: { user.relation = newRelation },
            revert: { user.relation = previousRelation },
            request: { [weak self] in
                try await self?.postRelation(action: action, userId: userId)
            }
        )
    }

    private func postRelation(action: String, userId: String) async throws {
        let _: OkStatusDTO? = try await apiService.send(
            toEndpoint: "/api/relations/\(action)",
            payload: RelationActionPayload(user: userId)
        )
    }

    /// The readers this account is actually close to — the only ones whose inventory is worth
    /// syncing, and the only ones the Profil calls « Réseau ».
    func friends(modelContext: ModelContext) -> [User] {
        getAllOtherUsers(modelContext: modelContext).filter { $0.relation == .friend }
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
