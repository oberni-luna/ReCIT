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
    func `a link opens the tab it names with the field down and the profile closed`() {
        let router: TabRouter = .init()
        router.select(.lists)
        router.openProfile()

        router.open(.group(id: "g1"), on: .community)

        #expect(router.selectedTab == .community)
        #expect(router.isProfilePresented == false)
        #expect(router.wantsSearchField == false)
        #expect(router.pendingLink == .init(destination: .group(id: "g1"), tab: .community))
    }

    @Test
    func `a link is pushed once`() {
        let router: TabRouter = .init()
        router.open(.author(uri: "wd:Q535"), on: .search)

        #expect(router.consumePendingLink(for: .search) == .author(uri: "wd:Q535"))
        #expect(router.consumePendingLink(for: .search) == nil)
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a link is pushed only by the tab it names`() {
        let router: TabRouter = .init()
        router.open(.group(id: "g1"), on: .community)

        #expect(router.consumePendingLink(for: .search) == nil)
        #expect(router.pendingLink?.tab == .community)
        #expect(router.consumePendingLink(for: .community) == .group(id: "g1"))
        #expect(router.pendingLink == nil)
    }

    @Test
    func `a book link still waits for Recherche`() {
        let router: TabRouter = .init()
        router.open(.author(uri: "wd:Q535"), on: .search)

        #expect(router.selectedTab == .search)
        #expect(router.consumePendingLink(for: .community) == nil)
        #expect(router.consumePendingLink(for: .search) == .author(uri: "wd:Q535"))
    }

    @Test
    func `a reader link opens their profile on Réseau`() {
        let router: TabRouter = .init()
        let reader: User = .init(
            _id: "reader",
            _rev: "1",
            username: "maxlath",
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 0
        )

        router.open(linkedUser: reader, myUserId: "me")

        #expect(router.selectedTab == .community)
        #expect(router.isProfilePresented == false)
        #expect(router.consumePendingLink(for: .community) == .user(user: reader))
    }

    @Test
    func `my own username opens the Profil sheet and pushes nothing`() {
        let router: TabRouter = .init()
        router.select(.lists)
        let myself: User = .init(
            _id: "me",
            _rev: "1",
            username: "OlivierB_test4",
            email: nil,
            position: nil,
            avatarURLValue: nil,
            itemCount: 0
        )

        router.open(linkedUser: myself, myUserId: "me")

        #expect(router.isProfilePresented)
        #expect(router.selectedTab == .lists)
        #expect(router.pendingLink == nil)
    }
}
