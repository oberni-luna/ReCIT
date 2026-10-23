//
//  ModelContainerMigrationTests.swift
//  ReCIT_iOSTests
//
//  An app update must open the store the previous version left on the phone. `ReCIT` builds its
//  container with no `VersionedSchema`, so every schema change rides on SwiftData's automatic
//  lightweight migration — and a migration that fails is the `fatalError` in
//  `ReCIT.makeModelContainer`, at launch, for every user. Issue 0103 added an entity, the groups:
//  this opens a store written without it.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ModelContainer migration", .serialized)
struct ModelContainerMigrationTests {

    /// The schema every version up to 1.3 shipped, before the groups were persisted.
    private static let schemaWithoutGroups: [any PersistentModel.Type] = [
        InventoryItem.self,
        User.self,
        Edition.self,
        Shelf.self,
        EntityList.self,
        EntityListItem.self,
        Author.self,
        Work.self,
        WpExtract.self,
        UserTransaction.self,
        TransactionMessage.self
    ]

    @Test("A store made before the groups were persisted opens with them, and keeps what it held")
    func storeWithoutGroupsOpens() throws {
        let url: URL = .temporaryDirectory.appending(path: "recit-migration-\(UUID().uuidString).store")

        do {
            let previous: Schema = .init(Self.schemaWithoutGroups)
            let container: ModelContainer = try .init(for: previous, configurations: [.init(schema: previous, url: url)])
            let context: ModelContext = .init(container)
            let me: User = Fixture.user(id: "user-1", username: "me")
            me.relation = .friend
            context.insert(me)
            context.insert(Fixture.inventoryItem(id: "item-1", ownerId: "user-1", edition: Fixture.edition()))
            try context.save()
        }

        let current: Schema = .init(Self.schemaWithoutGroups + [StoredGroup.self])
        let container: ModelContainer = try .init(for: current, configurations: [.init(schema: current, url: url)])
        let context: ModelContext = .init(container)

        let users: [User] = try context.fetch(FetchDescriptor<User>())
        #expect(users.map(\._id) == ["user-1"])
        #expect(users.first?.relation == .friend)
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).map(\._id) == ["item-1"])
        #expect(try context.fetch(FetchDescriptor<StoredGroup>()).isEmpty)

        // And the new table takes a group, members and all.
        let group: ReaderGroup = .init(
            id: "g",
            name: "Club",
            slug: nil,
            description: "",
            pictureURL: nil,
            searchable: true,
            open: false,
            admins: [.init(user: "user-1", invitor: nil, timestamp: 1)],
            members: [],
            invited: [.init(user: "user-2", invitor: "user-1", timestamp: 2)],
            declined: [],
            requested: []
        )
        context.insert(StoredGroup(group: group))
        try context.save()
        #expect(try context.fetch(FetchDescriptor<StoredGroup>()).first?.readerGroup == group)
    }
}
