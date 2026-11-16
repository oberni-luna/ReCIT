//
//  UserModel+Username.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension UserModel {
    /// The reader inventaire.io knows under `username`, in any case, put in the store like any
    /// other; `nil` when nobody goes by it.
    ///
    /// `by-usernames` answers under the lower-cased name, so its key is matched without regard to
    /// case. The id it gives goes through `by-ids`, the request that stores every other reader.
    /// - Parameters:
    ///   - username: A name as a link spells it, already checked against inventaire.io's rule.
    ///   - modelContext: The store the reader is written to.
    /// - Returns: The stored reader, or `nil` when nobody goes by `username`.
    /// - Throws: A `NetworkError` when inventaire.io cannot be asked.
    func getOrFetchUser(
        username: String,
        modelContext: ModelContext
    ) async throws -> User? {
        let answer: UsersDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/users/by-usernames?usernames=\(username)"
        )
        let match: UserDTO? = answer?.users.first { $0.key.lowercased() == username.lowercased() }?.value
        guard let match else { return nil }
        return try await getOrFetchUsers(modelContext: modelContext, userIds: [match._id]).first
    }
}
