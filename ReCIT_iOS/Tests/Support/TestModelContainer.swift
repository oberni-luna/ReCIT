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
    /// Every container built for a test is retained for the lifetime of the test
    /// process. Swift Testing runs suites in parallel in-process, and a container
    /// that gets deallocated mid-test tears down its backing store on a background
    /// queue — which, when stores are shared, can corrupt a store another parallel
    /// test is still writing to (observed as an `EXC_BREAKPOINT` inside SwiftData).
    /// Holding a strong reference keeps each store alive until the process exits.
    private static var retainedContainers: [ModelContainer] = []

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
        // A unique on-disk store per container fully isolates each test's data,
        // so tearing one container down never touches another's store.
        let url: URL = .temporaryDirectory.appending(path: "recit-tests-\(UUID().uuidString).store")
        let configuration: ModelConfiguration = .init(schema: schema, url: url)
        let container: ModelContainer = try .init(for: schema, configurations: [configuration])
        retainedContainers.append(container)
        return container
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
