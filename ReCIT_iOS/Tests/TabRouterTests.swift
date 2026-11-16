//
//  TabRouterTests.swift
//  ReCIT_iOSTests
//
//  The three ways into the Recherche tab, driven by calls rather than by taps: from another
//  tab, from the empty shelf's tag, and by tapping the tab that is already showing. And the
//  profile sheet, since feature 0038.
//
//  See PRD 0020 and issue 0116.
//

import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("TabRouter")
struct TabRouterTests {
    @Test("The app opens on the inventory, with no request waiting")
    func startsOnTheInventory() {
        let router: TabRouter = .init()

        #expect(router.selectedTab == .inventory)
        #expect(router.wantsSearchField == false)
        #expect(router.searchRootRequest == 0)
        #expect(router.isProfilePresented == false)
    }

    @Test("Selecting Recherche from another tab leaves the keyboard down")
    func selectingSearchDoesNotRaiseTheField() {
        let router: TabRouter = .init()

        router.select(.search)

        #expect(router.selectedTab == .search)
        #expect(router.wantsSearchField == false)
        #expect(router.searchRootRequest == 0)
    }

    @Test("The empty shelf's tag opens Recherche with the field up")
    func openSearchRaisesTheField() {
        let router: TabRouter = .init()

        router.openSearch()

        #expect(router.selectedTab == .search)
        #expect(router.wantsSearchField)
    }

    @Test("Tapping Recherche while it shows goes back to its root and raises the field")
    func reselectingSearchPopsAndRaisesTheField() {
        let router: TabRouter = .init()
        router.select(.search)

        router.select(.search)

        #expect(router.searchRootRequest == 1)
        #expect(router.wantsSearchField)
    }

    @Test("Tapping another tab while it shows asks nothing of the search")
    func reselectingAnotherTabIsQuiet() {
        let router: TabRouter = .init()

        router.select(.inventory)
        router.select(.lists)

        #expect(router.selectedTab == .lists)
        #expect(router.searchRootRequest == 0)
        #expect(router.wantsSearchField == false)
    }

    @Test("A field request is acted on once")
    func fieldRequestIsConsumedOnce() {
        let router: TabRouter = .init()
        router.openSearch()

        #expect(router.consumeSearchFieldRequest())
        #expect(router.consumeSearchFieldRequest() == false)
    }

    @Test("The search's invitation opens Réseau")
    func openNetworkSelectsTheNetworkTab() {
        let router: TabRouter = .init()
        router.select(.search)

        router.openNetwork()

        #expect(router.selectedTab == .community)
        #expect(router.wantsSearchField == false)
    }

    @Test("The avatar opens the profile without changing tab")
    func openProfilePresentsTheSheet() {
        let router: TabRouter = .init()
        router.select(.lists)

        router.openProfile()

        #expect(router.isProfilePresented)
        #expect(router.selectedTab == .lists)
    }

    @Test("A request for another tab closes the profile first")
    func tabRequestsCloseTheProfile() {
        let router: TabRouter = .init()

        router.openProfile()
        router.openNetwork()
        #expect(router.isProfilePresented == false)

        router.openProfile()
        router.openSearch()
        #expect(router.isProfilePresented == false)
        #expect(router.selectedTab == .search)
    }

    @Test
    func `a link opens the tab it names with the field down`() {
        let router: TabRouter = .init()
        router.select(.lists)

        #expect(router.open(.group(id: "g1"), on: .community, isModalUp: false) == nil)

        #expect(router.selectedTab == .community)
        #expect(router.isProfilePresented == false)
        #expect(router.wantsSearchField == false)
        #expect(router.pendingLink == .init(destination: .group(id: "g1"), tab: .community))
    }

    @Test
    func `a link is pushed once`() {
        let router: TabRouter = .init()
        _ = router.open(.author(uri: "wd:Q535"), on: .search, isModalUp: false)

        #expect(router.consumePendingLink(for: .search) == .author(uri: "wd:Q535"))
        #expect(router.consumePendingLink(for: .search) == nil)
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a link is pushed only by the tab it names`() {
        let router: TabRouter = .init()
        _ = router.open(.group(id: "g1"), on: .community, isModalUp: false)

        #expect(router.consumePendingLink(for: .search) == nil)
        #expect(router.pendingLink?.tab == .community)
        #expect(router.consumePendingLink(for: .community) == .group(id: "g1"))
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a book link still waits for Recherche`() {
        let router: TabRouter = .init()
        _ = router.open(.author(uri: "wd:Q535"), on: .search, isModalUp: false)

        #expect(router.selectedTab == .search)
        #expect(router.consumePendingLink(for: .community) == nil)
        #expect(router.consumePendingLink(for: .search) == .author(uri: "wd:Q535"))
    }

    @Test
    func `a link opened over a modal goes in a sheet and leaves the tabs alone`() {
        let router: TabRouter = .init()
        router.select(.lists)

        let sheet: LinkSheetContent? = router.open(.book(anchor: .edition(uri: "isbn:9782070360024")), on: .search, isModalUp: true)

        #expect(sheet == .destination(.book(anchor: .edition(uri: "isbn:9782070360024"))))
        #expect(router.selectedTab == .lists)
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a link opened over the Profil goes in a sheet and keeps the Profil up`() {
        let router: TabRouter = .init()
        router.openProfile()

        let sheet: LinkSheetContent? = router.open(.entityList(id: "l1"), on: .lists, isModalUp: false)

        #expect(sheet == .destination(.entityList(id: "l1")))
        #expect(router.isProfilePresented)
        #expect(router.selectedTab == .inventory)
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a reader link opens their profile on Réseau`() {
        let router: TabRouter = .init()
        let reader: User = .mock(id: "reader", username: "maxlath")

        #expect(router.open(linkedUser: reader, myUserId: "me", isModalUp: false) == nil)

        #expect(router.selectedTab == .community)
        #expect(router.isProfilePresented == false)
        #expect(router.consumePendingLink(for: .community) == .user(user: reader))
    }

    @Test
    func `a reader link opened over a modal goes in a sheet`() {
        let router: TabRouter = .init()
        let reader: User = .mock(id: "reader", username: "maxlath")

        let sheet: LinkSheetContent? = router.open(linkedUser: reader, myUserId: "me", isModalUp: true)

        #expect(sheet == .destination(.user(user: reader)))
        #expect(router.pendingLink == nil)
    }

    @Test
    func `my own username opens the Profil sheet and pushes nothing`() {
        let router: TabRouter = .init()
        router.select(.lists)
        let myself: User = .mock(id: "me", username: "OlivierB_test4")

        #expect(router.open(linkedUser: myself, myUserId: "me", isModalUp: false) == nil)

        #expect(router.isProfilePresented)
        #expect(router.selectedTab == .lists)
        #expect(router.pendingLink == nil)
    }

    @Test
    func `my own username over another modal opens the Profil in a sheet`() {
        let router: TabRouter = .init()
        let myself: User = .mock(id: "me", username: "OlivierB_test4")

        #expect(router.open(linkedUser: myself, myUserId: "me", isModalUp: true) == .profile)
        #expect(router.isProfilePresented == false)
    }

    @Test
    func `my own username with the Profil up opens nothing more`() {
        let router: TabRouter = .init()
        router.openProfile()
        let myself: User = .mock(id: "me", username: "OlivierB_test4")

        #expect(router.open(linkedUser: myself, myUserId: "me", isModalUp: true) == nil)
        #expect(router.isProfilePresented)
    }

    @Test
    func `a link opened before my user is known waits and is handed over once it is`() {
        let router: TabRouter = .init()

        #expect(router.receive(.entity(uri: "isbn:9782070360024"), isMyUserKnown: false) == nil)
        #expect(router.waitingLink == .entity(uri: "isbn:9782070360024"))

        #expect(router.takeWaitingLink() == .entity(uri: "isbn:9782070360024"))
        #expect(router.waitingLink == nil)
        #expect(router.takeWaitingLink() == nil)
    }

    @Test
    func `a newer link replaces the one waiting`() {
        let router: TabRouter = .init()

        _ = router.receive(.entity(uri: "isbn:9782070360024"), isMyUserKnown: false)
        _ = router.receive(.user(username: "maxlath"), isMyUserKnown: false)

        #expect(router.takeWaitingLink() == .user(username: "maxlath"))
    }

    @Test
    func `a router that replaces another keeps the link it was waiting with`() {
        let router: TabRouter = .init(waitingLink: .user(username: "maxlath"))

        #expect(router.takeWaitingLink() == .user(username: "maxlath"))
        #expect(router.selectedTab == .inventory)
    }

    @Test
    func `a link opened with my user known opens at once and waits for nothing`() {
        let router: TabRouter = .init()

        #expect(router.receive(.group(slug: "lecteurs"), isMyUserKnown: true) == .group(slug: "lecteurs"))
        #expect(router.waitingLink == nil)
    }
}
