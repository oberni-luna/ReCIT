//
//  UserModelWipeUserDataTests.swift
//  ReCIT_iOSTests
//
//  What a sign-out leaves behind. The bug was the half it forgot: friends, lists and
//  étagères outlived the account and turned up under the next one signed in on the phone.
//  The rule is one sentence — nothing that belongs to a person, everything that describes a
//  book — and each half gets a test.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("UserModel.wipeUserData", .serialized)
struct UserModelWipeUserDataTests {

    /// A store with something of every kind in it: me and a friend, our books, an étagère, a
    /// list, a transaction with a message, and the entities the books point at.
    private func populatedContext() throws -> ModelContext {
        let context: ModelContext = try TestStore.makeContext()

        let me: User = Fixture.user(id: "user-1", username: "me")
        let friend: User = Fixture.user(id: "user-2", username: "friend")
        context.insert(me)
        context.insert(friend)

        let author: Author = .init(uri: "wd:Q1", lastrevid: 1, name: "Annie Ernaux")
        let edition: Edition = Fixture.edition(uri: "isbn:9782072965821", title: "Les Années")
        let work: Work = .init(uri: "wd:Q2", lastrevid: 1, title: "Les Années", authors: [author], editions: [edition])
        context.insert(author)
        context.insert(work)

        let mine: InventoryItem = Fixture.inventoryItem(id: "item-1", ownerId: "user-1", edition: edition)
        let theirs: InventoryItem = Fixture.inventoryItem(id: "item-2", ownerId: "user-2", edition: edition)
        context.insert(mine)
        context.insert(theirs)

        let shelf: Shelf = .init(
            _id: "shelf-1",
            _rev: "rev-1",
            name: "Salon",
            slug: "salon",
            shelfDescription: "",
            ownerId: "user-1",
            visibility: [],
            colorHex: nil,
            created: .init(timeIntervalSince1970: 0),
            updated: nil
        )
        shelf.items = [mine]
        context.insert(shelf)

        let listItem: EntityListItem = .init(
            _id: "element-1",
            uri: "wd:Q2",
            ordinal: "0",
            created: .init(timeIntervalSince1970: 0),
            itemType: .work
        )
        let list: EntityList = .init(
            _id: "list-1",
            _rev: "rev-1",
            name: "À lire",
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            elements: [listItem],
            type: .work
        )
        context.insert(list)

        let transaction: UserTransaction = .init(
            _id: "t1",
            _rev: "1",
            item: theirs,
            owner: friend,
            requester: me,
            type: .lending,
            created: .init(timeIntervalSince1970: 0),
            messages: [],
            state: .requested,
            actions: [.init(action: .requested, timestamp: .init(timeIntervalSince1970: 0))],
            readStatus: .init(owner: true, requester: true)
        )
        context.insert(transaction)
        context.insert(
            TransactionMessage(
                _id: "m1",
                user: me,
                message: "Je peux ?",
                created: .init(timeIntervalSince1970: 0),
                transaction: transaction
            )
        )

        try context.save()
        return context
    }

    @Test("Nothing that belongs to a person survives a sign-out")
    func userDataGoes() throws {
        let context: ModelContext = try populatedContext()
        let model: UserModel = .init(apiService: MockAPIService())
        model.myUser = try context.fetch(FetchDescriptor<User>()).first { $0._id == "user-1" }

        try model.wipeUserData(modelContext: context)

        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Shelf>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<EntityList>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<EntityListItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<UserTransaction>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TransactionMessage>()).isEmpty)
        #expect(model.myUser == nil)
    }

    @Test("The books' own data stays, and no edition points at a book that is gone")
    func bibliographicDataStays() throws {
        let context: ModelContext = try populatedContext()
        let model: UserModel = .init(apiService: MockAPIService())

        try model.wipeUserData(modelContext: context)

        let editions: [Edition] = try context.fetch(FetchDescriptor<Edition>())
        #expect(editions.count == 1)
        #expect(editions.first?.items.isEmpty == true)
        #expect(try context.fetch(FetchDescriptor<Work>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Author>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Work>()).first?.authors.count == 1)
    }

    /// `RootView` runs it on every launch without a session, so the store is empty most times.
    @Test("Wiping an empty store is a no-op, not an error")
    func emptyStoreIsFine() throws {
        let context: ModelContext = try TestStore.makeContext()
        let model: UserModel = .init(apiService: MockAPIService())

        try model.wipeUserData(modelContext: context)
        try model.wipeUserData(modelContext: context)

        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty)
    }
}
