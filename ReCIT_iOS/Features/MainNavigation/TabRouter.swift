//
//  TabRouter.swift
//  ReCIT_iOS
//
//  Which tab is showing, and the requests one tab makes of another: « take me to the search
//  field », from the empty shelf, « take me to Réseau », from the search's invitation, and
//  « show me my profile », from the avatar at the top of Inventaire, Listes and Réseau.
//  `MainTabView` owns it and injects it, like `ShelfFocusModel`, because what it holds only
//  means something while the tabs are on screen — a sign-out drops it with them.
//
//  It exists because the search left the inventory for a tab of its own (PRD 0020). The empty
//  shelf's « Rechercher » tag used to raise a field on its own screen; now it has to change
//  tab *and* raise a field that belongs to another view, which neither view can do alone.
//
//  The field request is a flag the search tab consumes rather than an event it listens to: the
//  tab may not have been built yet when the request is made — the first time anyone opens it is
//  exactly the case — and a flag waits for it where an event would be gone.
//
//  The profile is a sheet rather than a tab since feature 0038: it is about the account, not
//  about the books, and the tab bar has room for four things a reader goes back to.
//
//  See PRD 0020, issue 0116 and feature 0038.
//

import Observation

@Observable @MainActor
final class TabRouter {
    /// The tab on screen. Written through `select(_:)`, so a tap on the tab already showing can be
    /// told apart from a tap on another one.
    private(set) var selectedTab: MainTabView.TabConfig = .inventory

    /// Whether the search tab should raise its field the next time it looks. Consumed once, by
    /// `consumeSearchFieldRequest()`.
    private(set) var wantsSearchField: Bool = false

    /// Bumped each time the search tab is asked to go back to its root. Its stack watches the
    /// value, not a flag: two requests in a row are two pops, and nothing has to clear it.
    private(set) var searchRootRequest: Int = 0

    /// Whether the profile sheet is up. Settable from outside because the sheet's own dismissal —
    /// a swipe down — writes it back through a binding.
    var isProfilePresented: Bool = false

    /// A tap on a tab. Tapping Recherche while it is already showing is the way back to a fresh
    /// search: its stack goes back to the root, and the field comes up.
    func select(_ tab: MainTabView.TabConfig) {
        if tab == .search, selectedTab == .search {
            searchRootRequest += 1
            wantsSearchField = true
        }
        selectedTab = tab
    }

    /// The Recherche tab, with its field up — what the empty shelf's « Rechercher » tag asks for.
    func openSearch() {
        isProfilePresented = false
        selectedTab = .search
        wantsSearchField = true
    }

    /// The Réseau tab — what « Chez mes amis » offers a reader with no friend yet (issue 0117).
    func openNetwork() {
        isProfilePresented = false
        selectedTab = .community
    }

    /// The profile sheet — what the avatar at the top of the three main tabs opens.
    func openProfile() {
        isProfilePresented = true
    }

    /// Whether the field was asked for, forgetting the request in the same move so it is acted
    /// on once.
    func consumeSearchFieldRequest() -> Bool {
        defer { wantsSearchField = false }
        return wantsSearchField
    }
}
