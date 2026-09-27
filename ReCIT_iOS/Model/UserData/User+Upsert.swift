//
//  User+Upsert.swift
//  ReCIT_iOS
//
//  Readers fetched from inventaire.io, merged into the store by id. Shared by the two places
//  users arrive from: `/api/users/by-ids`, and a group's `by-id`, which carries its members
//  already shaped as users.
//

import Foundation
import SwiftData

extension User {
    /// Updates the users already stored in place and inserts the others, then saves.
    /// In-place, never delete-and-reinsert (ADR 0001): an open profile keeps its object.
    @discardableResult
    static func upsert(
        _ dtos: [UserDTO],
        baseUrl: String,
        in modelContext: ModelContext
    ) throws -> [User] {
        var users: [User] = []
        for dto in dtos {
            let fetched: User = .init(userDTO: dto, baseUrl: baseUrl)
            let id: String = fetched._id
            let descriptor: FetchDescriptor<User> = .init(predicate: #Predicate { $0._id == id })
            if let user = try modelContext.fetch(descriptor).first {
                user.update(with: fetched)
                users.append(user)
            } else {
                modelContext.insert(fetched)
                users.append(fetched)
            }
        }
        try modelContext.save()
        return users
    }
}
