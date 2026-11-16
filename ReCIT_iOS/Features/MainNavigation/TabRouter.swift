//
//  TabRouter.swift
//  ReCIT_iOS
//
//  Which tab is showing, and the requests one tab makes of another: « take me to the search
//  field », from the empty shelf, « take me to Réseau », from the search's invitation, and
//  « show me my profile », from the avatar at the top of Inventaire, Listes and Réseau.
//  `RootView` owns it and injects it, rather than `MainTabView`, for the one thing in it that
//  means something before the tabs exist: an Ex-libris link opened signed out, which waits here
//  for the session and my user (issue 143). Everything else only means something while the tabs
//  are on screen, so a sign-out replaces the router with a fresh one, which keeps the link.
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
//  A link opened while something covers the tabs — a form's sheet, « Ranger mes livres », the
//  Profil — is not pushed on a tab hidden under it: the router hands its screen back, to open in
//  a sheet of its own above, so that what was up stays as it was (issue 143).
//
//  See PRD 0020, issue 0116, feature 0038 and issue 143.
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

    /// The screen an Ex-libris link asked for, waiting for the tab it names to push it. A flag the
    /// tab consumes, like the field request, for the same reason: on a cold launch the link
    /// arrives before the tab is built. Consumed once, by `consumePendingLink(for:)`.
    private(set) var pendingLink: PendingLink?

    /// An Ex-libris link opened before my user is known — signed out, or on a launch that has not
    /// read it from inventaire.io yet —, waiting to be opened once it is: my own username and my
    /// étagères are told apart by my id. In memory only: a link that dies with the app is opened
    /// again from where it was. A newer one replaces it.
    private(set) var waitingLink: DeepLink?

    /// - Parameter waitingLink: The link the router this one replaces was keeping: a session that
    ///   ends while a link waits for my user leaves it waiting for the next one.
    init(waitingLink: DeepLink? = nil) {
        self.waitingLink = waitingLink
    }

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

    /// An Ex-libris link the system hands the app: the one to open now, or `nil` when it waits.
    /// - Parameters:
    ///   - link: The link the system handed the app.
    ///   - isMyUserKnown: Whether there is a session, and my user read from inventaire.io in it.
    /// - Returns: The link to open now, or `nil` when it waits for my user.
    func receive(_ link: DeepLink, isMyUserKnown: Bool) -> DeepLink? {
        guard isMyUserKnown else {
            waitingLink = link
            return nil
        }
        return link
    }

    /// The link that waited for my user, forgetting it in the same move so it is opened once.
    func takeWaitingLink() -> DeepLink? {
        defer { waitingLink = nil }
        return waitingLink
    }

    /// A screen an Ex-libris link names. Pushed on `tab` over whatever it showed when nothing
    /// covers the tabs; else handed back, to open in a sheet over what does.
    /// - Parameters:
    ///   - destination: The screen the link names.
    ///   - tab: The tab whose stack pushes it.
    ///   - isModalUp: Whether anything is presented over the tabs. The Profil sheet counts
    ///     whatever this says.
    /// - Returns: What the link sheet shows, or `nil` when the screen is pushed on its tab.
    func open(
        _ destination: NavigationDestination,
        on tab: MainTabView.TabConfig,
        isModalUp: Bool
    ) -> LinkSheetContent? {
        guard isModalUp == false, isProfilePresented == false else {
            return .destination(destination, tab: tab)
        }
        push(destination, on: tab)
        return nil
    }

    /// A reader an Ex-libris link names: their profile, on Réseau or in a link sheet as any other
    /// screen. Me: the Profil sheet, in a link sheet over another modal, and nothing more when it
    /// is already up. Told apart by id rather than by name: inventaire.io still answers to a
    /// reader's former name, which a link may carry.
    /// - Returns: What the link sheet shows, or `nil` when nothing goes in one.
    func open(
        linkedUser user: User,
        myUserId: String?,
        isModalUp: Bool
    ) -> LinkSheetContent? {
        guard user._id == myUserId else {
            return open(.user(user: user), on: .community, isModalUp: isModalUp)
        }
        guard isModalUp, isProfilePresented == false else {
            openProfile()
            return nil
        }
        return .profile
    }

    /// A link sheet the router asked for that could not be presented — the Profil's flag still
    /// up while its sheet goes, a modal gone in between: its screen pushed on its tab, the
    /// Profil closed so the tab shows; the Profil sheet itself for my own username.
    func openWithoutSheet(_ content: LinkSheetContent) {
        switch content {
        case let .destination(destination, tab):
            push(destination, on: tab)
        case .profile:
            openProfile()
        }
    }

    /// The screen a link asked of `tab`, forgetting it in the same move so it is pushed once. A
    /// link meant for another tab stays where it is, for that tab to take.
    func consumePendingLink(for tab: MainTabView.TabConfig) -> NavigationDestination? {
        guard let pendingLink, pendingLink.tab == tab else { return nil }
        self.pendingLink = nil
        return pendingLink.destination
    }

    /// Whether the field was asked for, forgetting the request in the same move so it is acted
    /// on once.
    func consumeSearchFieldRequest() -> Bool {
        defer { wantsSearchField = false }
        return wantsSearchField
    }

    private func push(_ destination: NavigationDestination, on tab: MainTabView.TabConfig) {
        isProfilePresented = false
        selectedTab = tab
        pendingLink = .init(destination: destination, tab: tab)
    }
}
