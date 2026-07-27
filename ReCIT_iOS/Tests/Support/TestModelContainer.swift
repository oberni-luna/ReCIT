//
//  TestModelContainer.swift
//  ReCIT_iOSTests
//
//  Builds an in-memory SwiftData container covering every @Model so tests get
//  a clean, isolated store with no on-disk persistence.
//

import Foundation
import SwiftData
@testable import ReCIT_iOS

@MainActor
enum TestStore {
    static func makeContainer() throws -> ModelContainer {
        let schema: Schema = .init([
            InventoryItem.self,
            User.self,
            Edition.self,
            EntityList.self,
            EntityListItem.self,
            Author.self,
            Work.self,
            WpExtract.self,
            UserTransaction.self,
            TransactionMessage.self
        ])
        let configuration: ModelConfiguration = .init(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeContext() throws -> ModelContext {
        try makeContainer().mainContext
    }
}

// MARK: - Builders

@MainActor
enum Fixture {
    static func user(
        id: String = "user-1",
        username: String = "tester"
    ) -> User {
        .init(
            _id: id,
            _rev: "rev-1",
            username: username,
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 0
        )
    }

    static func edition(
        uri: String = "isbn:0000000000000",
        title: String = "Untitled",
        authorNames: [String] = []
    ) -> Edition {
        .init(uri: uri, title: title, lang: nil, authorNames: authorNames)
    }

    static func inventoryItem(
        id: String = "item-1",
        ownerId: String = "user-1",
        edition: Edition,
        searchIndex: String = ""
    ) -> InventoryItem {
        let item: InventoryItem = .init(
            _id: id,
            _rev: "rev-1",
            transaction: .inventorying,
            visibility: [.public],
            ownerId: ownerId,
            created: .init(timeIntervalSince1970: 0),
            updated: nil,
            busy: nil,
            details: "",
            edition: edition
        )
        item.searchIndex = searchIndex
        return item
    }
}
