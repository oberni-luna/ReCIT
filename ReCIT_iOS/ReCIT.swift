//
//  ReCIT_iOSApp.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/08/2025.
//

import SwiftUI
import SwiftData

@main
struct ReCIT: App {
    /// `nil` while running unit tests: the app must not spin up its own
    /// on-disk `ModelContainer`, otherwise it coexists with the containers the
    /// tests create and SwiftData traps on duplicate schema registration.
    private let sharedModelContainer: ModelContainer?

    @State private var authModel: AuthModel

    init() {
        // First, and before the session is read: building `AuthService` restores the keychain's
        // cookies into the jar, so a scenario asking for a signed-out launch has to have wiped
        // them by now. Inert outside a `-uitest` run. See `UITestHooks`.
        UITestHooks.prepareLaunch()

        DesignSystem.start()
        _authModel = State(initialValue: .init(authService: .init(config: .init())))
        sharedModelContainer = Self.isRunningTests ? nil : Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                RootView()
                    .environment(authModel)
                    .modelContainer(sharedModelContainer)
                    .tint(.foregroundTinted)
            } else {
                // Test host: no UI, no container, no startup networking.
                EmptyView()
            }
        }
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTest") != nil
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema: Schema = .init([
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
        ])
        let modelConfiguration: ModelConfiguration = .init(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
