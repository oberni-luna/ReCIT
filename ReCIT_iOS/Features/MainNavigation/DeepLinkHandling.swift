//
//  DeepLinkHandling.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 15/11/2026.
//

import SwiftData
import SwiftUI

/// Opens an Ex-libris link (`DeepLink`) the system hands the app: a book or an author is pushed on
/// the Recherche tab, the one stack that belongs to no particular place in the app; a reader or a
/// group on Réseau, where they are found otherwise; a list on Listes; a copy of a book or an
/// étagère on Inventaire. My own username opens the Profil sheet, as the avatar does. A link the
/// app cannot open — unknown entity, reader, group, list, copy or étagère, one I may not see, a
/// stranger's étagère, network down — goes to the same page on inventaire.io in Safari, which is
/// what the link does when the app is not installed.
///
/// On `RootView`, around both branches (issue 143): a link opened signed out waits in the router
/// and opens once signed in or up, with the same rules. A link opened while a modal covers the
/// tabs opens in a `LinkSheet` over it, presented by `LinkSheetPresenter` with
/// `sheetEnvironment`, rather than pushed on a tab hidden underneath.
struct DeepLinkHandling: ViewModifier {
    let router: TabRouter
    /// What the link sheet's screens read: UIKit presents it with an empty environment.
    let sheetEnvironment: AppEnvironment

    @Environment(AuthModel.self) private var authModel: AuthModel
    @Environment(EntityModel.self) private var entityModel: EntityModel
    @Environment(UserModel.self) private var userModel: UserModel
    @Environment(GroupModel.self) private var groupModel: GroupModel
    @Environment(ListModel.self) private var listModel: ListModel
    @Environment(InventoryModel.self) private var inventoryModel: InventoryModel
    @Environment(ShelfModel.self) private var shelfModel: ShelfModel
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.openURL) private var openURL: OpenURLAction

    /// Me and my friends: the readers whose étagères may enter the store.
    private var shelfOwnersOpenedInApp: Set<String> {
        let friends: [String] = userModel.friends(modelContext: modelContext).map(\._id)
        return .init(friends + [userModel.myUser?._id].compactMap(\.self))
    }

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard
                    let link = DeepLink(url: url),
                    let linkToOpen = router.receive(link, isSignedIn: authModel.isAuthenticated)
                else {
                    return
                }
                Task { await open(linkToOpen) }
            }
            .onChange(of: authModel.isAuthenticated) { _, isAuthenticated in
                guard isAuthenticated, let link = router.takeLinkAwaitingSignIn() else { return }
                Task { await open(link) }
            }
    }

    private func open(_ link: DeepLink) async {
        if await openInApp(link) {
            return
        }
        if let webURL = link.webURL {
            openURL(webURL)
        }
    }

    /// Whether the screen the link names was found, and opened.
    private func openInApp(_ link: DeepLink) async -> Bool {
        switch link {
        case let .entity(uri):
            return open(await destination(forLinkedURI: uri), on: .search)
        case let .user(username):
            guard let user = try? await userModel.getOrFetchUser(username: username, modelContext: modelContext) else {
                return false
            }
            present(
                router.open(
                    linkedUser: user,
                    myUserId: userModel.myUser?._id,
                    isModalUp: LinkSheetPresenter.isModalUp
                )
            )
            return true
        case let .group(slug):
            let id: String? = try? await groupModel.groupId(slug: slug)
            return open(id.map { .group(id: $0) }, on: .community)
        case let .list(id, elementId):
            let list: EntityList? = await linkedList(id: id)
            return open(list.map { .init(linkedList: $0, elementId: elementId) }, on: .lists)
        case let .item(id):
            let destination: NavigationDestination? = await .linkedItem(
                id: id,
                inventoryModel: inventoryModel,
                modelContext: modelContext
            )
            return open(destination, on: .inventory)
        case let .shelf(id):
            let destination: NavigationDestination? = await .linkedShelf(
                id: id,
                ownedByOneOf: shelfOwnersOpenedInApp,
                shelfModel: shelfModel,
                modelContext: modelContext
            )
            return open(destination, on: .inventory)
        }
    }

    /// Opens `destination` on `tab`, or in a link sheet over the modal that covers it, and says
    /// whether there was one to open.
    private func open(
        _ destination: NavigationDestination?,
        on tab: MainTabView.TabConfig
    ) -> Bool {
        guard let destination else { return false }
        present(router.open(destination, on: tab, isModalUp: LinkSheetPresenter.isModalUp))
        return true
    }

    /// The link sheet the router asked for, if any, over the modal on top.
    private func present(_ content: LinkSheetContent?) {
        switch content {
        case let .destination(destination):
            LinkSheetPresenter.present(LinkSheet(destination).modifier(sheetEnvironment))
        case .profile:
            LinkSheetPresenter.present(ProfileSheet().modifier(sheetEnvironment))
        case nil:
            break
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

    /// The list the store holds, mine or a friend's; else inventaire.io's, stored with its creator
    /// read alongside, so that it opens read-only like a friend's.
    private func linkedList(id: String) async -> EntityList? {
        if let stored = try? listModel.storedList(id: id, modelContext: modelContext) {
            return stored
        }
        guard let list = try? await listModel.fetchList(id: id, modelContext: modelContext) else { return nil }
        if let creatorId = list.creatorId {
            _ = try? await userModel.getOrFetchUsers(modelContext: modelContext, userIds: [creatorId])
        }
        return list
    }
}
