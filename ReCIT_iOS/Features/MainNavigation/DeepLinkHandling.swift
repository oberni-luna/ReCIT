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
            let destination: NavigationDestination? = try? await entityModel.destination(
                forLinkedURI: uri,
                modelContext: modelContext
            )
            if let destination {
                router.open(destination)
            } else if let webURL = link.webURL {
                openURL(webURL)
            }
        }
    }
}
