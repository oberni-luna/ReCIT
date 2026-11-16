//
//  SearchLocalPreviewStore.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// The store Recherche's Listes, Ami·es and Groupes are previewed on: my lists and Léa's, four
/// friends and a pending invitation, two groups, with me signed in.
struct SearchLocalPreviewStore: PreviewModifier {
    static let myUserId: String = "me"

    static func makeSharedContext() throws -> ModelContainer {
        let container: ModelContainer = try .init(
            for: EntityList.self,
            User.self,
            StoredGroup.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let context: ModelContext = container.mainContext

        context.insert(reader(id: myUserId, username: "Moi", relation: .none))
        let friends: [String] = ["Léa", "Bastien", "Clara", "Amina"]
        friends.forEach { context.insert(reader(id: $0, username: $0, relation: .friend)) }
        context.insert(reader(id: "Isabel", username: "Isabel", relation: .requestSent))

        let lists: [EntityList] = [
            .mock(id: "preview-mine-1", name: "Belles histoires", creatorId: myUserId),
            .mock(id: "preview-mine-2", name: "La Belle Époque", type: .author, creatorId: myUserId),
            .mock(id: "preview-lea", name: "Belles lettres à lire", creatorId: "Léa")
        ]
        lists.forEach(context.insert)

        let member: [GroupMembership] = [.init(user: myUserId, invitor: nil, timestamp: 0)]
        let groups: [ReaderGroup] = [
            group(id: "preview-club", name: "Club des belles lettres", members: member),
            group(id: "preview-voisins", name: "Belleville lit", members: member)
        ]
        groups.forEach { context.insert(StoredGroup(group: $0)) }

        return container
    }

    private static func reader(
        id: String,
        username: String,
        relation: UserRelation
    ) -> User {
        let user: User = .init(
            _id: id,
            _rev: "1",
            username: username,
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 0
        )
        user.relation = relation
        return user
    }

    private static func group(
        id: String,
        name: String,
        members: [GroupMembership]
    ) -> ReaderGroup {
        .init(
            id: id,
            name: name,
            slug: nil,
            description: "",
            pictureURL: nil,
            searchable: true,
            open: false,
            admins: [],
            members: members,
            invited: [],
            declined: [],
            requested: []
        )
    }

    func body(
        content: Content,
        context: ModelContainer
    ) -> some View {
        let apiService: APIService = .init(env: .production)
        let userModel: UserModel = .init(apiService: apiService)
        let myUserId: String = Self.myUserId
        userModel.myUser = try? context.mainContext
            .fetch(FetchDescriptor<User>(predicate: #Predicate { $0._id == myUserId }))
            .first
        return content
            .modelContainer(context)
            .environment(userModel)
            .environment(InventoryModel(apiService: apiService))
            .environment(GroupModel(apiService: apiService))
    }
}
