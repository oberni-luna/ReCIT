//
//  E2EScenarioTests+Links.swift
//  ReCIT_iOSUITests
//
//  The deep-links leg of the scenario (features 0092–0097): Ex-libris links on
//  `link.exlibris.lunabee.ovh`, opened the way a link touched in another app is — through the
//  system, which hands a universal link to the app only if it has associated the domain.
//
//  **Played while the run's list and étagères still exist**, between « Vérification du contenu
//  de la liste » and their deletion, so the two objects only this run knows the ids of can be
//  shared and then opened. Their ids are on no screen: the link is taken from « Partager »,
//  copied, and pasted into the Recherche field, whose value the runner can read. The runner
//  reading the pasteboard itself would raise iOS's paste prompt over a blocked main thread.
//
//  The books, the author and the friend are inventaire.io objects that do not move: « Lucioles »
//  (scanned earlier in the run), Victor Hugo (`wd:Q535`), and OlivierB, a friend of the test
//  account, whose own lists and étagères are not public — hence the share round trip above.
//
//  Created by Olivier Berni on 17/11/2026.
//

import XCTest

extension E2EScenarioTests {

    // MARK: - What the links point at

    /// The domain every Ex-libris link is on.
    private static let linkHost: String = "https://link.exlibris.lunabee.ovh"

    /// Safari, where a link the app does not take ends up.
    private static let safariBundleIdentifier: String = "com.apple.mobilesafari"

    /// « Lucioles », the first book the run scans: in the store by now, so its link opens
    /// without a request.
    private static let linkedBook: (path: String, title: String) = (
        path: "/entity/isbn:9782370493002",
        title: "Lucioles"
    )

    /// Victor Hugo, read through `by-uris` because the app has no reason to hold him.
    private static let linkedAuthor: (path: String, name: String) = (
        path: "/entity/wd:Q535",
        name: "Victor Hugo"
    )

    /// A friend of the test account, as in « Recherche 1 ».
    private static let linkedFriend: String = "OlivierB"

    /// A path on the link domain that no Ex-libris link has: two segments under `/users`.
    private static let refusedPath: String = "/users/x/inventory"

    // MARK: - The steps

    /// Plays the eight link steps. Every one is non-critical and leaves the app on a tab's root
    /// with nothing over it, whatever happened, so the cleanup steps after it start as before.
    @MainActor
    static func playLinkSteps(
        driver: E2EDriver,
        app: XCUIApplication,
        username: String,
        listName: String,
        shelfName: String
    ) {
        driver.step("Lien vers un livre", critical: false) {
            try openBookLink(driver: driver, app: app)
        }
        driver.step("Lien vers un·e auteur·ice", critical: false) {
            try openAuthorLink(driver: driver, app: app)
        }
        driver.step("Lien vers un·e ami·e", critical: false) {
            try openFriendLink(driver: driver, app: app)
        }
        driver.step("Lien vers mon profil", critical: false) {
            try openOwnProfileLink(username: username, driver: driver, app: app)
        }
        driver.step("Lien par-dessus le Profil", critical: false) {
            try openLinkOverProfile(driver: driver, app: app)
        }
        driver.step("Partage de la liste, puis son lien", critical: false) {
            try shareAndOpenList(listName, driver: driver, app: app)
        }
        driver.step("Partage de l'étagère « \(shelfName) », puis son lien", critical: false) {
            try shareAndOpenShelf(shelfName, driver: driver, app: app)
        }
        driver.step("Lien illisible, rendu à inventaire.io", critical: false) {
            try openRefusedLink(driver: driver, app: app)
        }
    }

    // MARK: - One step each

    /// The first link of the run, and the one that says whether iOS associated the domain: a
    /// link that lands in Safari here means every step after it is about Safari, not the app.
    @MainActor
    private static func openBookLink(driver: E2EDriver, app: XCUIApplication) throws -> String {
        // The searches left a book pushed on Recherche: walked back first, so the book screen
        // waited for below is the link's and not that one.
        try settle(driver: driver)
        let searchTab: XCUIElement = app.tabBars.buttons[E2EDriver.Tab.search.rawValue]
        try driver.tap(searchTab, "l'onglet « Recherche »", until: { isSelected(.search, app: app) })
        try driver.popBack(to: .search)
        try settle(driver: driver)
        let url: URL = try link(linkedBook.path)

        try open(url, driver: driver, app: app, "la fiche du livre") {
            driver.exists("e2e.book.menu")
        }
        // One query for « this title, on screen »: reading `label` of an element that a push has
        // just replaced raises inside XCTest.
        let linked: XCUIElement = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier == %@ AND label CONTAINS[cd] %@",
                    "e2e.entityTitle",
                    linkedBook.title
                )
            )
            .firstMatch
        let found: Bool = linked.waitForExistence(timeout: E2EDriver.defaultTimeout)
        let title: XCUIElement = driver.any("e2e.entityTitle")
        let shown: String = found ? linkedBook.title : (title.exists ? title.label : "(aucun titre)")
        let onSearch: Bool = isSelected(.search, app: app)
        try settle(driver: driver)

        guard found else {
            throw E2EFailure("Le lien \(url.path()) a ouvert « \(shown) », pas « \(linkedBook.title) ».")
        }
        guard onSearch else {
            throw E2EFailure("« \(shown) » s'est ouvert hors de l'onglet Recherche.")
        }
        return "\(url.path()) → fiche « \(shown) », sur Recherche"
    }

    @MainActor
    private static func openAuthorLink(driver: E2EDriver, app: XCUIApplication) throws -> String {
        try settle(driver: driver)
        let url: URL = try link(linkedAuthor.path)

        try open(url, driver: driver, app: app, "l'écran Auteur·ice") {
            driver.exists("e2e.author.share")
        }
        let name: XCUIElement = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", linkedAuthor.name))
            .firstMatch
        let named: Bool = name.waitForExistence(timeout: E2EDriver.defaultTimeout)
        try settle(driver: driver)

        guard named else {
            throw E2EFailure("L'écran Auteur·ice s'est ouvert sans le nom « \(linkedAuthor.name) ».")
        }
        return "\(url.path()) → Auteur·ice « \(linkedAuthor.name) », lu par by-uris"
    }

    @MainActor
    private static func openFriendLink(driver: E2EDriver, app: XCUIApplication) throws -> String {
        try settle(driver: driver)
        let url: URL = try link("/users/\(linkedFriend)")

        try open(url, driver: driver, app: app, "le profil de \(linkedFriend)") {
            driver.exists("e2e.user.tabs")
        }
        let named: Bool = app.staticTexts[linkedFriend].waitForExistence(timeout: E2EDriver.defaultTimeout)
        try settle(driver: driver)

        guard named else {
            throw E2EFailure("Un profil s'est ouvert, sans le nom « \(linkedFriend) ».")
        }
        return "\(url.path()) → profil de \(linkedFriend), sur Réseau"
    }

    /// My own name is not a reader's profile pushed on Réseau but the Profil sheet.
    @MainActor
    private static func openOwnProfileLink(
        username: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> String {
        try settle(driver: driver)
        let url: URL = try link("/users/\(username)")

        try open(url, driver: driver, app: app, "la feuille Profil") {
            driver.exists("e2e.profile.close")
        }
        let pushedOnNetwork: Bool = driver.exists("e2e.user.tabs")
        try closeProfile(driver: driver)

        guard pushedOnNetwork == false else {
            throw E2EFailure("Mon propre nom a aussi poussé un profil de lecteur·ice sur Réseau.")
        }
        return "\(url.path()) → la feuille Profil, rien de poussé"
    }

    /// A link that arrives while a sheet is up opens in a sheet of its own over it (0097), with
    /// « Fermer » back to the sheet as it was.
    @MainActor
    private static func openLinkOverProfile(driver: E2EDriver, app: XCUIApplication) throws -> String {
        try settle(driver: driver)
        try driver.tap(
            driver.any("e2e.profile.open"),
            "l'avatar du profil",
            until: { driver.exists("e2e.profile.close") }
        )
        let url: URL = try link(linkedBook.path)

        do {
            try open(url, driver: driver, app: app, "la feuille du lien, par-dessus le Profil") {
                driver.exists("e2e.linkSheet.close") && driver.exists("e2e.book.menu")
            }
            try driver.tap(
                driver.any("e2e.linkSheet.close"),
                "« Fermer » de la feuille du lien",
                until: { driver.exists("e2e.linkSheet.close") == false }
            )
        } catch {
            try? closeProfile(driver: driver)
            throw error
        }

        let profileKept: Bool = driver.holds({ driver.exists("e2e.profile.close") }, within: 5)
        try closeProfile(driver: driver)

        guard profileKept else {
            throw E2EFailure("« Fermer » a refermé la feuille du lien, mais le Profil n'était plus dessous.")
        }
        return "\(url.path()) avec le Profil ouvert → la fiche dans une feuille au-dessus, « Fermer » rend le Profil"
    }

    /// My list, made visible to my friends (a private one shares nothing), shared, and its link
    /// opened from the inventory.
    @MainActor
    private static func shareAndOpenList(
        _ listName: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> String {
        try driver.openTab(.lists)
        try driver.popBack(to: .lists)
        try driver.tap(
            app.staticTexts[listName],
            "la liste « \(listName) »",
            until: { driver.exists("e2e.lists.add") == false }
        )

        try driver.tap(
            app.navigationBars.buttons["Modifier"],
            "le bouton « Modifier » de la liste",
            until: { driver.exists("e2e.listForm.visibility") }
        )
        try pick(
            "Mes ami·es",
            in: driver.any("e2e.listForm.visibility"),
            "« Visible par »",
            driver: driver,
            app: app
        )
        try driver.tap(
            driver.any("e2e.listForm.submit"),
            "le bouton « Envoyer »",
            until: { driver.exists("e2e.listForm.visibility") == false }
        )

        let url: URL = try copySharedLink(
            from: "e2e.list.share",
            leaving: .lists,
            expecting: "/lists/",
            driver: driver,
            app: app
        )
        try settle(driver: driver)

        try open(url, driver: driver, app: app, "la liste « \(listName) »") {
            driver.exists("e2e.list.share") && app.staticTexts[listName].exists
        }
        let onLists: Bool = isSelected(.lists, app: app) || app.tabBars.count == 0
        try settle(driver: driver)

        guard onLists else {
            throw E2EFailure("La liste s'est ouverte hors de l'onglet Listes.")
        }
        return "Visible par « Mes ami·es », « Partager » › « Copier » → \(url.path()) → « \(listName) » sur Listes"
    }

    /// The same round trip for an étagère, opened from Recherche this time so the push on
    /// Inventaire is the link's and not what was left on the stack.
    @MainActor
    private static func shareAndOpenShelf(
        _ shelfName: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> String {
        try driver.openTab(.inventory)
        try driver.popBack(to: .inventory)
        let label: XCUIElement = try driver.waitForIdentifier(
            "e2e.shelfLabel.\(shelfName)",
            "l'étiquette de l'étagère « \(shelfName) »",
            timeout: E2EDriver.syncTimeout
        )
        try driver.tap(label, "l'étiquette de l'étagère « \(shelfName) »", until: {
            app.navigationBars.buttons["Modifier"].exists
        })

        try driver.tap(
            app.navigationBars.buttons["Modifier"],
            "le bouton « Modifier » de l'étagère",
            until: { driver.exists("e2e.shelfForm.name") }
        )
        let visibility: XCUIElement = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Visibilité"))
            .firstMatch
        try pick("Ami·es", in: visibility, "« Visibilité »", driver: driver, app: app)
        try driver.tap(
            driver.any("e2e.shelfForm.submit"),
            "le bouton « Enregistrer »",
            until: { driver.exists("e2e.shelfForm.name") == false }
        )

        let url: URL = try copySharedLink(
            from: "e2e.shelf.share",
            leaving: .inventory,
            expecting: "/shelves/",
            driver: driver,
            app: app
        )

        try open(url, driver: driver, app: app, "l'étagère « \(shelfName) »") {
            driver.exists("e2e.shelf.share")
        }
        let named: Bool = app.navigationBars.staticTexts[shelfName].exists
            || app.staticTexts[shelfName].exists
        let onInventory: Bool = isSelected(.inventory, app: app) || app.tabBars.count == 0
        try settle(driver: driver)

        guard named else {
            throw E2EFailure("Une étagère s'est ouverte, sans le nom « \(shelfName) ».")
        }
        guard onInventory else {
            throw E2EFailure("L'étagère s'est ouverte hors de l'onglet Inventaire.")
        }
        return "Visibilité « Ami·es », « Partager » › « Copier » → \(url.path()) → « \(shelfName) » sur Inventaire"
    }

    /// A path the app cannot read goes to the same path on inventaire.io, in Safari.
    ///
    /// **Only meaningful once « Lien vers un livre » is OK**: if iOS has not associated the
    /// domain, Safari opens the link itself and the server's `302` lands on the same page.
    @MainActor
    private static func openRefusedLink(driver: E2EDriver, app: XCUIApplication) throws -> String {
        try settle(driver: driver)
        let url: URL = try link(refusedPath)
        let safari: XCUIApplication = .init(bundleIdentifier: safariBundleIdentifier)

        XCUIDevice.shared.system.open(url)
        let inSafari: Bool = safari.wait(for: .runningForeground, timeout: E2EDriver.defaultTimeout)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: E2EDriver.defaultTimeout)
        try settle(driver: driver)

        guard inSafari else {
            throw E2EFailure("\(url.path()) n'a pas été rendu à Safari au bout de \(Int(E2EDriver.defaultTimeout)) s.")
        }
        return "\(url.path()) → Safari, sur inventaire.io ; retour à Ex-libris"
    }

    // MARK: - Moves

    @MainActor
    private static func link(_ path: String) throws -> URL {
        guard let url = URL(string: linkHost + path) else {
            throw E2EFailure("Lien mal formé : \(path)")
        }
        return url
    }

    /// Opens `url` through the system, as a link touched in another app, and waits for what it
    /// should show. A link that went to Safari instead is said as such, and the app brought back.
    @MainActor
    private static func open(
        _ url: URL,
        driver: E2EDriver,
        app: XCUIApplication,
        _ what: String,
        until arrived: () -> Bool
    ) throws {
        let safari: XCUIApplication = .init(bundleIdentifier: safariBundleIdentifier)
        XCUIDevice.shared.system.open(url)

        let landed: Bool = driver.holds(
            { arrived() || safari.state == .runningForeground },
            within: E2EDriver.syncTimeout
        )
        if safari.state == .runningForeground {
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: E2EDriver.defaultTimeout)
            throw E2EFailure(
                "\(url.path()) s'est ouvert dans Safari, pas dans Ex-libris : iOS n'a pas associé "
                + "link.exlibris.lunabee.ovh à l'app (fichier apple-app-site-association pas encore lu)."
            )
        }
        guard landed else {
            throw E2EFailure("\(what) n'est pas apparu·e au bout de \(Int(E2EDriver.syncTimeout)) s après \(url.path()).")
        }
    }

    /// Chooses `option` in a form's menu picker.
    @MainActor
    private static func pick(
        _ option: String,
        in picker: XCUIElement,
        _ what: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws {
        let choice: XCUIElement = app.buttons[option]
        try driver.tap(picker, "le choix \(what)", until: { choice.exists })
        try driver.tap(choice, "« \(option) »", until: { choice.exists == false })
    }

    /// « Partager » › « Copier » on the screen showing `shareIdentifier`, then the link read
    /// back by pasting it into Recherche's field. Leaves the app on the inventory's root.
    @MainActor
    private static func copySharedLink(
        from shareIdentifier: String,
        leaving tab: E2EDriver.Tab,
        expecting pathPrefix: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> URL {
        let copy: XCUIElement = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Copier"))
            .firstMatch
        try driver.tap(
            try driver.waitForIdentifier(shareIdentifier, "le bouton « Partager »"),
            "le bouton « Partager »",
            until: { copy.exists }
        )
        try driver.tap(copy, "« Copier » de la feuille de partage", until: { copy.exists == false })
        try driver.openTab(tab)

        let pasted: String = try pasteIntoSearch(driver: driver, app: app)
        try settle(driver: driver)

        guard pasted.hasPrefix(linkHost + pathPrefix), let url = URL(string: pasted) else {
            throw E2EFailure("Le lien copié n'est pas un lien \(pathPrefix) d'Ex-libris : « \(pasted) ».")
        }
        return url
    }

    /// Pastes the pasteboard into Recherche's field through its edit menu — a paste the user
    /// asked for, so iOS shows no prompt — and returns what the field then holds.
    @MainActor
    private static func pasteIntoSearch(driver: E2EDriver, app: XCUIApplication) throws -> String {
        let tab: XCUIElement = app.tabBars.buttons[E2EDriver.Tab.search.rawValue]
        try driver.tap(tab, "l'onglet « Recherche »", until: { isSelected(.search, app: app) })
        try driver.popBack(to: .search)

        let field: XCUIElement = app.searchFields.firstMatch
        try driver.waitFor(field, "le champ de l'onglet Recherche")
        try driver.tap(field, "le champ de l'onglet Recherche")
        let current: String = field.value as? String ?? ""
        if current.isEmpty == false && current != field.placeholderValue {
            field.buttons.firstMatch.tap()
        }

        let paste: XCUIElement = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Coller"))
            .firstMatch
        for _ in 0..<3 where paste.exists == false {
            field.press(forDuration: 1.2)
            _ = paste.waitForExistence(timeout: 3)
        }
        try driver.tap(paste, "« Coller » dans le champ de Recherche", until: { paste.exists == false })

        var value: String = ""
        _ = driver.holds(
            {
                value = field.value as? String ?? ""
                return value.hasPrefix("https://")
            },
            within: 5
        )

        try closeSearch(driver: driver, app: app)
        return value
    }

    /// Whether `tab` is the selected tab, asked as one query.
    ///
    /// **Never `buttons[…].isSelected`**: a pushed screen hides the tab bar (0088), and reading a
    /// property of an element that is not there raises inside XCTest and ends the whole run.
    @MainActor
    private static func isSelected(_ tab: E2EDriver.Tab, app: XCUIApplication) -> Bool {
        app.tabBars.buttons
            .matching(NSPredicate(format: "label == %@ AND selected == true", tab.rawValue))
            .firstMatch
            .exists
    }

    /// Leaves an active search, if one is: iOS 26 closes it with a cross beside the field, iOS 18
    /// with « Annuler ». Left active, its keyboard covers the tab bar and every later tab change
    /// taps nothing — and on iOS 27 merely selecting Recherche activates its field.
    @MainActor
    private static func closeSearch(driver: E2EDriver, app: XCUIApplication) throws {
        guard app.keyboards.count > 0 else { return }

        let close: XCUIElement = app.buttons
            .matching(NSPredicate(format: "label IN %@", ["Annuler", "Fermer", "Close", "Cancel"]))
            .firstMatch
        guard close.exists else { return }

        try driver.tap(close, "la fermeture de la recherche", until: { app.keyboards.count == 0 })
    }

    /// Back to the inventory's root with nothing over it: the next step starts from there.
    @MainActor
    private static func settle(driver: E2EDriver) throws {
        try closeSearch(driver: driver, app: driver.app)
        if driver.exists("e2e.linkSheet.close") {
            driver.any("e2e.linkSheet.close").tap()
        }
        if driver.exists("e2e.profile.close") {
            try closeProfile(driver: driver)
        }
        try driver.openTab(.inventory)
        try driver.popBack(to: .inventory)
    }

    @MainActor
    private static func closeProfile(driver: E2EDriver) throws {
        try driver.tap(
            driver.any("e2e.profile.close"),
            "la croix du Profil",
            until: { driver.exists("e2e.profile.close") == false }
        )
    }
}
