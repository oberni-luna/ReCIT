//
//  FriendItemsPreviewStore.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftData
import SwiftUI

/// The store friends' copies of a book are previewed on: « Petit pays », Gaël Faye, in two
/// editions, one lent by Léa and one Samir only lists, with me signed in and owning none.
struct FriendItemsPreviewStore: PreviewModifier {
    static let workURI: String = "wd:Q-preview-petit-pays"
    static let myUserId: String = "me"

    static func makeSharedContext() throws -> ModelContainer {
        let container: ModelContainer = try .init(
            for: Work.self,
            Author.self,
            Edition.self,
            InventoryItem.self,
            User.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let context: ModelContext = container.mainContext

        let author: Author = .init(uri: "wd:Q-preview-gael-faye", lastrevid: 1, name: "Gaël Faye")
        let work: Work = .init(uri: workURI, lastrevid: 1, title: "Petit pays")
        context.insert(author)
        context.insert(work)
        work.authors = [author]
        context.insert(reader(id: myUserId, username: "Moi"))

        let friends: [(username: String, transaction: TransactionType)] = [
            ("Léa", .lending),
            ("Samir", .inventorying)
        ]
        for (index, friend) in friends.enumerated() {
            let edition: Edition = .init(
                uri: "isbn:preview-petit-pays-\(index)",
                title: "Petit pays",
                lang: "fr",
                authorNames: ["Gaël Faye"]
            )
            context.insert(edition)
            edition.works = [work]

            let owner: User = reader(id: friend.username, username: friend.username)
            let item: InventoryItem = .init(
                _id: "preview-friend-item-\(index)",
                _rev: "1",
                transaction: friend.transaction,
                visibility: [],
                ownerId: owner._id,
                created: .now.addingTimeInterval(-86_400 * Double(index + 1)),
                updated: nil,
                busy: nil,
                edition: edition
            )
            context.insert(item)
            item.owner = owner
        }
        return container
    }

    private static func reader(
        id: String,
        username: String
    ) -> User {
        .init(
            _id: id,
            _rev: "1",
            username: username,
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 0
        )
    }

    private static func userModel(
        signedInFrom context: ModelContainer,
        apiService: APIService
    ) -> UserModel {
        let userModel: UserModel = .init(apiService: apiService)
        let myUserId: String = Self.myUserId
        userModel.myUser = try? context.mainContext
            .fetch(FetchDescriptor<User>(predicate: #Predicate { $0._id == myUserId }))
            .first
        return userModel
    }

    func body(
        content: Content,
        context: ModelContainer
    ) -> some View {
        let apiService: APIService = .init(env: .production)
        let userModel: UserModel = Self.userModel(signedInFrom: context, apiService: apiService)
        content
            .modelContainer(context)
            .environment(userModel)
            .environment(InventoryModel(apiService: apiService))
            .environment(TransactionModel(apiService: apiService, userModel: userModel))
    }
}
