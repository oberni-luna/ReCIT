//
//  GroupModel+Picture.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation
import SwiftData

extension GroupModel {
    /// Writes the group's picture, server first, in a task this model owns: the bytes are
    /// uploaded, then named in `update-settings`; `nil` takes the picture away.
    ///
    /// **Not optimistic.** The upload is the slow half, and a picture shown before it lands would
    /// too often have to be taken back. The group shows the new picture once the server has
    /// agreed, and keeps its old one, with a word in the snack bar, when it refuses.
    func updatePicture(
        _ imageData: Data?,
        on groupId: String,
        modelContext: ModelContext
    ) {
        let actor: String? = myUserId
        inFlightTask = Task { [weak self] in
            do {
                try await self?.writePicture(
                    imageData,
                    on: groupId,
                    actor: actor,
                    modelContext: modelContext
                )
            } catch {
                self?.errorReporter?.report(error)
            }
        }
    }

    /// Nothing is written to the group when the account changed during the round trip, nor when
    /// the group has gone from the store and from memory meanwhile.
    private func writePicture(
        _ imageData: Data?,
        on groupId: String,
        actor: String?,
        modelContext: ModelContext
    ) async throws {
        let setting: GroupSetting = .picture(try await uploadedPicturePath(imageData))
        try await putSetting(setting, groupId: groupId)

        guard actor == myUserId, let current = group(id: groupId, in: modelContext) else { return }
        place(setting.applied(to: current, baseUrl: apiService.baseUrl()), in: modelContext)
        try modelContext.save()
    }

    /// `POST /api/images/upload` into `groups`, which answers the path it filed the picture under.
    private func uploadedPicturePath(_ imageData: Data?) async throws -> String? {
        guard let imageData else { return nil }
        guard let path = try await apiService.upload(
            imageData: imageData,
            fileName: "group.jpg",
            fieldName: "picture",
            container: "groups",
            debug: false
        ) else {
            throw NetworkError.badResponse
        }
        return path
    }
}
