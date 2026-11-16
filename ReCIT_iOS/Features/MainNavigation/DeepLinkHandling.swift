//
//  DeepLinkHandling.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 15/11/2026.
//

import SwiftData
import SwiftUI

/// Opens an Ex-libris link (`DeepLink`) the system hands the app: the screen it names is pushed on
/// the Recherche tab, the one stack that belongs to no particular place in the app. A link the app
/// cannot open — unknown entity, network down — goes to the same page on inventaire.io in Safari,
/// which is what the link does when the app is not installed.
///
/// On `MainTabView` only: a link opened before signing in has no tabs to land on, and is dropped.
struct DeepLinkHandling: ViewModifier {
    let router: TabRouter

    @Environment(EntityModel.self) private var entityModel: EntityModel
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.openURL) private var openURL: OpenURLAction

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard let link = DeepLink(url: url) else { return }
                Task { await open(link) }
            }
    }

    private func open(_ link: DeepLink) async {
        switch link {
        case let .entity(uri):
            if let destination = await destination(forLinkedURI: uri) {
                router.open(destination)
            } else if let webURL = link.webURL {
                openURL(webURL)
            }
        }
    }

    /// An `isbn:` uri is an edition by construction; any other one — `wd:`, `inv:` — may be a work,
    /// an edition or a person, and only inventaire.io knows which, so it is asked through `by-uris`,
    /// the same request the book screen makes.
    private func destination(forLinkedURI uri: String) async -> NavigationDestination? {
        if let edition = NavigationDestination(linkedISBN: uri) {
            return edition
        }
        guard let entity = try? await entityModel.fetchEntities(modelContext: modelContext, uris: [uri])?.first else {
            return nil
        }
        return .init(linkedEntity: entity)
    }
}
