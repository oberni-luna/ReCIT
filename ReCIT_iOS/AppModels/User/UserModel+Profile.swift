//
//  UserModel+Profile.swift
//  ReCIT_iOS
//
//  Writing the public half of the account — picture, name, bio, position — from « Modifier le
//  profil ». Server first, like « Modifier l'édition »: the form stays open until the server has
//  agreed, and `myUser` takes each value only once it has.
//

import Foundation
import SwiftData

extension UserModel {

    /// Sends `changes` one by one, in order, and writes each onto `myUser` as it lands.
    ///
    /// Stops at the first refusal and throws it, carrying what had already gone through: there is
    /// no transaction on the server's side, so the caller keeps those and offers to send the rest.
    func saveProfile(
        _ changes: [ProfileChange],
        modelContext: ModelContext
    ) async throws(ProfileSaveFailure) {
        var landed: [ProfileChange] = []

        for change in changes {
            do {
                try await write(change)
            } catch {
                throw ProfileSaveFailure(refused: change.kind, landed: landed, underlying: error)
            }
            landed.append(change)
            try? modelContext.save()
        }
    }

    private func write(_ change: ProfileChange) async throws {
        switch change {
        case .picture(let imageData):
            // The picture is uploaded first and named by the path the server files it under,
            // `/img/users/<hash>` — the only shape `picture` accepts. `nil` takes it away.
            var path: String?
            if let imageData {
                guard let uploaded = try await apiService.upload(
                    imageData: imageData,
                    fileName: "avatar.jpg",
                    fieldName: "avatar",
                    container: "users",
                    debug: false
                ) else {
                    throw NetworkError.badResponse
                }
                path = uploaded
            }
            try await updateUserAttribute("picture", value: path)
            myUser?.avatarURLValue = apiService.absoluteImageUrl(path)

        case .username(let username):
            try await updateUserAttribute("username", value: username)
            myUser?.username = username

        case .bio(let bio):
            try await updateUserAttribute("bio", value: bio)
            myUser?.bio = bio

        case .position(let coordinates):
            let value: [Double]? = coordinates.map { [$0.latitude, $0.longitude] }
            try await updateUserAttribute("position", value: value)
            myUser?.position = coordinates
        }
    }

    /// One `PUT /api/user`, in its slot.
    func updateUserAttribute<Value: Codable & Sendable>(_ attribute: String, value: Value) async throws {
        let apiService: APIServicing = apiService
        try await userUpdatePacer.run {
            let _: OkStatusDTO? = try await apiService.send(
                toEndpoint: "/api/user",
                method: "PUT",
                payload: UserAttributeUpdate(attribute: attribute, value: value)
            )
        }
    }

    /// The account's Gravatar, as JPEG bytes ready to upload like any picture, or `nil` when its
    /// address has none.
    ///
    /// Downloaded rather than handed to the server as a url: the form shows the picture before it
    /// is saved, and saving it is then the same upload as a photograph's. The download goes to
    /// gravatar.com, which needs nothing of ours, hence the cookieless session.
    func gravatarImage() async throws -> Data? {
        let answer: GravatarDTO? = try await apiService.fetchData(fromEndpoint: "/api/images/gravatar")
        guard let address = answer?.url, let url = URL(string: address) else { return nil }

        let (data, response): (Data, URLResponse) = try await URLSession.cookieless.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        return CoverImageReducer.jpegData(from: data)
    }
}
