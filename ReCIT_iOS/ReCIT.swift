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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InventoryItem.self,
            User.self,
            Edition.self,
            EntityList.self,
            Author.self,
            Work.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var authModel: AuthModel = .init(authService: .init(config: .init()))

    init() {
        DesignSystem.start()

    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authModel)
                .modelContainer(sharedModelContainer)
        }
    }
}
