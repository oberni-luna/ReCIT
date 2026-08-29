//
//  E2EScenarioTests.swift
//  ReCIT_iOSUITests
//
//  The whole app, once through, on a simulator, against the real inventaire.io: sign in, scan
//  two books, find three more by hand, make two étagères and fill them by dragging, make a list
//  and put two works in it, then take every one of those things back out again and sign out.
//
//  **It is a scenario, not an assertion suite.** Nothing here calls `XCTFail`: every step files
//  a line in `E2EReport` — what it did, on what, a screenshot, and OK or KO with the reason —
//  and the run carries on so the compte-rendu covers the whole journey rather than stopping at
//  the first surprise. `E2EDriver.step(critical:)` is where that judgement lives: a failure that
//  makes the rest meaningless (no session, no scanner) marks what follows SKIP instead of
//  pretending to test it.
//
//  **It writes to a real account and cleans up after itself.** The last four steps are the
//  cleanup, and they are steps like any other — a run that leaves books behind says so in its
//  own report. The account and its password come from the environment (`E2E_USERNAME`,
//  `E2E_PASSWORD`), passed through `TEST_RUNNER_…` by `scripts/e2e.sh`, so no credential is
//  written down here.
//
//  **The two seams it needs in the app are in `UITestHooks`**: the simulator has no camera, so
//  the scanner's placard hands back this scenario's own ISBNs one at a time; and the session
//  outlives an uninstall in the keychain, so the launch wipes it. Everything else is ordinary
//  tapping against the shipped screens.
//
//  Étagère and list names carry a per-run stamp, so a run that failed halfway and left one
//  behind cannot make the next run's creation collide with it.
//
//  See `docs/features/0012-end-to-end-scenario.md`.
//

import XCTest

final class E2EScenarioTests: XCTestCase {

    // MARK: - What the run is made of

    /// The two books scanned, in order. Both are the barcodes on the photographs the scenario was
    /// written from — « Lucioles » and « Penss et les plis du monde » — and both resolve on
    /// inventaire.io, which is what makes the scan step meaningful rather than a tap on a placard.
    private static let scannedIsbns: [String] = [
        "9782370493002",
        "9782413013518"
    ]

    /// The three searches, one per kind: a French author, an English one, and a title looked up
    /// directly. Each ends on a book screen and adds the copy to the inventory.
    private static let searches: [(kind: String, query: String)] = [
        (kind: "auteur français", query: "Victor Hugo"),
        (kind: "auteur anglais", query: "Virginia Woolf"),
        (kind: "titre", query: "Le Petit Prince")
    ]

    // MARK: - The run

    @MainActor
    func testFullJourney() throws {
        continueAfterFailure = true

        let environment: [String: String] = ProcessInfo.processInfo.environment
        let username: String = environment["E2E_USERNAME"] ?? ""
        let password: String = environment["E2E_PASSWORD"] ?? ""

        let report: E2EReport = .init(
            scenario: "Parcours complet Ex-libris",
            device: UIDevice.current.name,
            account: username.isEmpty ? "(non fourni)" : username
        )
        defer { report.finish() }

        let app: XCUIApplication = makeApp()
        let driver: E2EDriver = .init(app: app, report: report)

        /// What every name created by this run is suffixed with, so two runs never collide and a
        /// leftover from a failed run never blocks a fresh one.
        let stamp: String = Self.runStamp()
        let firstShelfName: String = "E2E Romans \(stamp)"
        let secondShelfName: String = "E2E Essais \(stamp)"
        let listName: String = "E2E Liste \(stamp)"

        // Titles picked up along the way, so the report can name what each step acted on.
        var scannedTitles: [String] = []
        var searchedTitles: [String] = []
        /// Set by the accueil step when it chose « Scanner mes livres », so the next step knows
        /// the scanner is already opening and does not go looking for another way in.
        var scannerWasOpenedFromWelcome: Bool = false

        // MARK: 1. Launch

        driver.step("Lancement de l'application") {
            guard username.isEmpty == false, password.isEmpty == false else {
                throw E2EFailure(
                    "Identifiants absents. Lancez le test via scripts/e2e.sh, "
                    + "qui exporte TEST_RUNNER_E2E_USERNAME et TEST_RUNNER_E2E_PASSWORD."
                )
            }

            app.launch()
            try driver.waitForIdentifier("e2e.welcome.signIn", "l'écran d'accueil « Ex-libris »")
            return "Écran d'accueil affiché, session vierge"
        }

        // MARK: 2. Sign in

        driver.step("Connexion") {
            try driver.tap("e2e.welcome.signIn", "le bouton « Se connecter » de l'accueil")

            let usernameField: XCUIElement = app.textFields.firstMatch
            try driver.type(username, into: usernameField, "le champ identifiant")

            let passwordField: XCUIElement = app.secureTextFields.firstMatch
            try driver.type(password, into: passwordField, "le champ mot de passe")

            try driver.tap("e2e.login.submit", "le bouton « Se connecter »")

            guard driver.holds(
                { app.tabBars.firstMatch.exists },
                within: E2EDriver.syncTimeout
            ) else {
                // The screen says why under the two fields — a refused password, an unreachable
                // server, inventaire.io rate-limiting the sign-ins of a machine that has run
                // this scenario three times in ten minutes. Carrying that sentence into the
                // report is the difference between a KO somebody can act on and one they cannot.
                let stated: String = driver.any("e2e.login.failure").label
                throw E2EFailure(
                    stated.isEmpty
                        ? "La session ne s'est pas ouverte au bout de 90 s, sans message à l'écran."
                        : "Connexion refusée. L'écran indique : « \(stated) »"
                )
            }
            return "Connecté en tant que \(username)"
        }

        // MARK: 3. The first-launch cover, answered by scanning

        driver.step("Accueil premier lancement", critical: false) {
            let primary: XCUIElement = driver.any("e2e.onboarding.primary")
            guard primary.waitForExistence(timeout: E2EDriver.syncTimeout) else {
                return "Pas d'accueil présenté (inventaire non vide, ou déjà répondu)"
            }

            // Answering by « Scanner mes livres » is both the answer and the way into the
            // scanner, which is the path a new user actually walks — and, since iOS 26 hides
            // the search tab's toolbar, the app's most reliable one.
            try driver.tap(primary, "« Scanner mes livres »", until: {
                driver.exists("e2e.onboarding.primary") == false
            })
            scannerWasOpenedFromWelcome = true
            return "Accueil affiché, répondu par « Scanner mes livres »"
        }

        // MARK: 4. The scanner

        driver.step("Ouverture du scanner") {
            if scannerWasOpenedFromWelcome,
               driver.any("e2e.scan.finish").waitForExistence(timeout: E2EDriver.defaultTimeout) {
                return "Session de scan ouverte depuis l'accueil"
            }

            // No accueil — the inventory was not empty, which happens when a previous run left
            // books behind. The debug section replays the same accueil on demand, and it is the
            // only entry into the scanner that does not depend on the state of the library.
            try driver.openTab(.settings)
            try driver.tap(
                driver.any("e2e.debug.scanOnboarding"),
                "la ligne debug « Ouvrir l'onboarding scan »",
                until: { driver.exists("e2e.onboarding.primary") }
            )
            try driver.tap(
                driver.any("e2e.onboarding.primary"),
                "« Scanner mes livres »",
                until: { driver.exists("e2e.scan.finish") }
            )
            return "Session de scan ouverte depuis la section debug (pas d'accueil)"
        }

        // MARK: 5–6. Scan the two books

        for (offset, isbn) in Self.scannedIsbns.enumerated() {
            driver.step("Scan du livre \(offset + 1)", critical: false) {
                let title: String = try Self.scanOneBook(driver: driver, app: app)
                scannedTitles.append(title)
                return "ISBN \(isbn) → « \(title) » ajouté à l'inventaire"
            }
        }

        // MARK: 7. End the scanning session

        driver.step("Fin de la session de scan") {
            // The condition is what the session *ends on*, never the row it has already
            // cleared: `tap(_:until:)` returns without tapping when its condition already
            // holds, and by this point there is no pending row left to disappear.
            try driver.tap(
                driver.any("e2e.scan.finish"),
                "le bouton « Terminer »",
                until: {
                    driver.exists("e2e.onboarding.later") || driver.isShowingRoot(of: .inventory)
                },
                settle: E2EDriver.defaultTimeout
            )

            // The bilan is owed to a session that filed books into a library with no étagère,
            // which is exactly this one — but it is the gate's decision, so both endings are
            // accepted here.
            let later: XCUIElement = driver.any("e2e.onboarding.later")
            if later.waitForExistence(timeout: 10) {
                try driver.tap(later, "« Plus tard » du bilan de scan", until: {
                    driver.exists("e2e.onboarding.later") == false
                })
                try driver.waitUntil("le retour aux onglets", timeout: E2EDriver.syncTimeout) {
                    driver.isShowingRoot(of: .inventory)
                }
                return "Bilan de scan affiché (\(scannedTitles.count) livre(s)) puis écarté"
            }

            try driver.waitUntil("le retour aux onglets", timeout: E2EDriver.syncTimeout) {
                driver.isShowingRoot(of: .inventory)
            }
            return "Session close sans bilan"
        }

        // MARK: 8–10. Three books found by hand

        for (offset, search) in Self.searches.enumerated() {
            driver.step("Recherche \(offset + 1) — \(search.kind) : « \(search.query) »", critical: false) {
                let title: String = try Self.searchAndAdd(
                    query: search.query,
                    driver: driver,
                    app: app
                )
                searchedTitles.append(title)
                return "« \(title) » ajouté à l'inventaire depuis la recherche « \(search.query) »"
            }
        }

        // MARK: 11. The sorting surface

        driver.step("Ouverture de l'écran de tri") {
            try driver.openTab(.inventory)
            try driver.tap(
                driver.any("e2e.shelves.sort"),
                "le bouton « Ranger »",
                until: { driver.exists("e2e.sort.newShelf") || driver.exists("e2e.sort.close") }
            )
            try driver.waitForIdentifier(
                "e2e.sort.newShelf",
                "la surface de tri (fin de la synchronisation)",
                timeout: E2EDriver.syncTimeout
            )
            return "Surface de tri ouverte, \(driver.all("e2e.sortBook").count) livre(s) à ranger"
        }

        // MARK: 12–13. Two étagères

        for name in [firstShelfName, secondShelfName] {
            driver.step("Création de l'étagère « \(name) »", critical: false) {
                try driver.tap(
                    driver.any("e2e.sort.newShelf"),
                    "la tuile « Nouvelle étagère »",
                    until: { driver.exists("e2e.shelfForm.name") }
                )

                let field: XCUIElement = driver.textField("e2e.shelfForm.name")
                try driver.type(name, into: field, "le champ « Nom de l'étagère »")
                try driver.tap(
                    driver.any("e2e.shelfForm.submit"),
                    "le bouton « Créer »",
                    until: { driver.exists("e2e.shelfForm.name") == false }
                )

                try driver.waitForIdentifier(
                    "e2e.sortShelf.\(name)",
                    "la carte de l'étagère « \(name) » dans la grille"
                )
                return "Étagère « \(name) » ajoutée au brouillon de rangement"
            }
        }

        // MARK: 14–15. Two books dragged onto them

        for (offset, name) in [firstShelfName, secondShelfName].enumerated() {
            driver.step("Glisser-déposer d'un livre sur « \(name) »", critical: false) {
                let books: XCUIElementQuery = driver.all("e2e.sortBook")
                guard books.count > 0 else {
                    throw E2EFailure("Aucun livre à ranger dans le bandeau du bas.")
                }

                let book: XCUIElement = books.element(boundBy: 0)
                let bookLabel: String = book.label
                let countBefore: Int = books.count

                let target: XCUIElement = try driver.waitForIdentifier(
                    "e2e.sortShelf.\(name)",
                    "la carte « \(name) »"
                )

                // Two attempts: a drag the system reads as a scroll leaves the screen exactly as
                // it was, and one retry is cheaper than a KO on the flakiest gesture in the run.
                for attempt in 0..<2 {
                    driver.drag(book, to: target)
                    if driver.holds({ driver.all("e2e.sortBook").count < countBefore }, within: 8) {
                        break
                    }
                    if attempt == 1 {
                        throw E2EFailure(
                            "Le livre n'a pas quitté le bandeau « Livres à ranger » après deux "
                            + "tentatives de glisser-déposer."
                        )
                    }
                }
                return "Livre \(offset + 1) « \(bookLabel) » déposé sur « \(name) »"
            }
        }

        // MARK: 16. Apply

        driver.step("Application du rangement", critical: false) {
            let apply: XCUIElement = try driver.waitForIdentifier(
                "e2e.sort.apply",
                "le bouton « Appliquer le rangement »"
            )
            try driver.tap(apply, "le bouton « Appliquer le rangement »")

            // The footer's own account of the run, not the state of the button: every control
            // on this screen is disabled *while* a run is in flight, which is the same state as
            // "nothing left to save" — so waiting on the button would report a run that had
            // barely started as a run that had landed.
            let landed: XCUIElement = try driver.waitForIdentifier(
                "e2e.sort.applyReport",
                "le compte-rendu « … étagères ont été enregistrées »",
                timeout: E2EDriver.syncTimeout
            )
            return "Rangement écrit sur inventaire.io — \(landed.label)"
        }

        // MARK: 17. Leave the flow

        driver.step("Fermeture de l'écran de tri", critical: false) {
            try driver.tap(
                driver.any("e2e.sort.close"),
                "la croix de fermeture",
                until: { driver.isShowingRoot(of: .inventory) }
            )
            return "Retour à l'inventaire"
        }

        // MARK: 18. A list

        driver.step("Création de la liste « \(listName) »", critical: false) {
            try driver.openTab(.lists)
            try driver.tap(
                driver.any("e2e.lists.add"),
                "le bouton « Ajouter » des listes",
                until: { driver.exists("e2e.listForm.name") }
            )

            let field: XCUIElement = driver.textField("e2e.listForm.name")
            try driver.type(listName, into: field, "le champ « Nom »")
            try driver.tap(
                driver.any("e2e.listForm.submit"),
                "le bouton « Envoyer »",
                until: { driver.exists("e2e.listForm.name") == false }
            )

            try driver.waitFor(
                app.staticTexts[listName],
                "la liste « \(listName) » dans l'onglet Listes"
            )
            return "Liste « \(listName) » créée (type : œuvres)"
        }

        // MARK: 19–20. Two works into it

        for index in 0..<2 {
            driver.step("Ajout de l'œuvre \(index + 1) à la liste", critical: false) {
                let title: String = try Self.addBookToList(
                    bookIndex: index,
                    listName: listName,
                    driver: driver,
                    app: app
                )
                return "« \(title) » ajouté à « \(listName) »"
            }
        }

        // MARK: 21. What the list holds

        driver.step("Vérification du contenu de la liste", critical: false) {
            try driver.openTab(.lists)
            try driver.popBack(to: .lists)
            try driver.tap(
                app.staticTexts[listName],
                "la liste « \(listName) »",
                until: { driver.exists("e2e.listItemRow") || driver.exists("e2e.lists.add") == false }
            )

            try driver.waitUntil("le contenu de la liste", timeout: E2EDriver.defaultTimeout) {
                driver.all("e2e.listItemRow").count > 0
            }
            return "\(driver.all("e2e.listItemRow").count) œuvre(s) présentes dans « \(listName) »"
        }

        // MARK: 22. Delete the list

        driver.step("Suppression de la liste", critical: false) {
            if driver.exists("e2e.listItemRow") == false {
                try driver.openTab(.lists)
                try driver.popBack(to: .lists)
                try driver.tap(
                    app.staticTexts[listName],
                    "la liste « \(listName) »",
                    until: { driver.exists("e2e.lists.add") == false }
                )
            }

            try driver.tap(
                app.navigationBars.buttons["Modifier"],
                "le bouton « Modifier » de la liste",
                until: { driver.exists("e2e.listForm.delete") }
            )
            try driver.tap(
                driver.any("e2e.listForm.delete"),
                "le bouton « Supprimer la liste »",
                until: { app.staticTexts[listName].exists == false }
            )
            return "Liste « \(listName) » supprimée"
        }

        // MARK: 23–24. Delete the shelves

        // Alphabetically, which is the order the carousel puts them in: the first card is the
        // only one fully on screen, and deleting it promotes the next one into its place. Taking
        // them in creation order would mean reaching for a card that is three quarters off the
        // right edge.
        for name in [firstShelfName, secondShelfName].sorted() {
            driver.step("Suppression de l'étagère « \(name) »", critical: false) {
                try driver.openTab(.inventory)
                try driver.popBack(to: .inventory)

                let label: XCUIElement = try driver.waitForIdentifier(
                    "e2e.shelfLabel.\(name)",
                    "l'étiquette de l'étagère « \(name) »",
                    timeout: E2EDriver.syncTimeout
                )
                try driver.tap(label, "l'étiquette de l'étagère « \(name) »", until: {
                    app.navigationBars.buttons["Modifier"].exists
                })

                try driver.tap(
                    app.navigationBars.buttons["Modifier"],
                    "le bouton « Modifier » de l'étagère",
                    until: { driver.exists("e2e.shelfForm.delete") }
                )
                try driver.tap(
                    driver.any("e2e.shelfForm.delete"),
                    "le bouton « Supprimer l'étagère »",
                    until: { driver.exists("e2e.shelfForm.confirmDelete") }
                )
                try driver.tap(
                    driver.any("e2e.shelfForm.confirmDelete"),
                    "la confirmation de suppression",
                    until: { driver.exists("e2e.shelfForm.confirmDelete") == false }
                )

                try driver.waitUntil("la disparition de l'étagère", timeout: E2EDriver.syncTimeout) {
                    driver.exists("e2e.shelfLabel.\(name)") == false
                }
                return "Étagère « \(name) » supprimée (les livres sont conservés)"
            }
        }

        // MARK: 25. Delete the books

        driver.step("Suppression des livres de l'inventaire", critical: false) {
            try driver.openTab(.inventory)
            try driver.popBack(to: .inventory)

            var removed: [String] = []
            // Bounded rather than "while there are books left": a removal that silently failed
            // would otherwise loop until the test timed out with nothing to say.
            for _ in 0..<12 {
                if driver.all("e2e.inventoryBook").count == 0 {
                    // The books are a lazy stack under the étagères carousel, so "no row on
                    // screen" is not "no book left". Scroll before believing it.
                    app.scrollViews.firstMatch.swipeUp()
                    _ = driver.holds({ driver.all("e2e.inventoryBook").count > 0 }, within: 3)
                }
                guard driver.all("e2e.inventoryBook").count > 0 else { break }

                let row: XCUIElement = driver.all("e2e.inventoryBook").element(boundBy: 0)
                let label: String = row.label
                let countBefore: Int = driver.all("e2e.inventoryBook").count

                try driver.tap(row, "le premier livre de l'inventaire", until: {
                    driver.exists("e2e.book.menu")
                })
                try driver.tap(
                    driver.any("e2e.book.menu"),
                    "le menu « … » du livre",
                    until: { driver.exists("e2e.book.remove") }
                )
                try driver.tap(
                    driver.any("e2e.book.remove"),
                    "« Supprimer de mon inventaire »",
                    until: { driver.exists("e2e.book.confirmRemove") }
                )
                try driver.tap(
                    driver.any("e2e.book.confirmRemove"),
                    "la confirmation de suppression",
                    until: { driver.exists("e2e.book.confirmRemove") == false }
                )

                try driver.waitFor(
                    app.staticTexts["Supprimé !"],
                    "la confirmation de suppression du livre",
                    timeout: E2EDriver.defaultTimeout
                )

                removed.append(label)
                try driver.popBack(to: .inventory)
                try driver.waitUntil("la mise à jour de la liste des livres", timeout: 20) {
                    driver.all("e2e.inventoryBook").count < countBefore
                }
            }

            // The section header is the authority, not the rows: it counts the whole library
            // where the stack only draws what is on screen.
            guard driver.holds({ app.staticTexts["Tous les livres · 0"].exists }, within: 20) else {
                throw E2EFailure(
                    "L'inventaire n'est pas vide après \(removed.count) suppression(s) — "
                    + "voir le compteur « Tous les livres » sur la capture."
                )
            }
            return "\(removed.count) livre(s) supprimé(s) : \(removed.joined(separator: ", "))"
        }

        // MARK: 26. Sign out

        driver.step("Déconnexion", critical: false) {
            try driver.openTab(.settings)
            try driver.tap(
                driver.any("e2e.profile.logout"),
                "le bouton « Se déconnecter »",
                until: { driver.exists("e2e.welcome.signIn") },
                settle: E2EDriver.defaultTimeout
            )
            return "Session fermée, retour à l'écran d'accueil"
        }
    }

    // MARK: - The app under test

    @MainActor
    private func makeApp() -> XCUIApplication {
        let app: XCUIApplication = .init()
        app.launchArguments = [
            UITestHooksArguments.activation,
            UITestHooksArguments.reset,
            // French, whatever the simulator is set to: a handful of system-drawn controls can
            // only be found by their title, and a machine left in English would fail on every
            // one of them for no reason worth reporting.
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR"
        ]
        app.launchEnvironment["E2E_SCAN_CODES"] = Self.scannedIsbns.joined(separator: ",")
        return app
    }

    /// A short, sortable token for the names this run creates.
    private static func runStamp() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "MMdd-HHmmss"
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter.string(from: .now)
    }

    // MARK: - Composite moves

    /// One book through the scanner: tap the placard, wait for the row to resolve, file it, wait
    /// for the row to clear. Returns the title the row showed, which is what the report names.
    @MainActor
    private static func scanOneBook(driver: E2EDriver, app: XCUIApplication) throws -> String {
        // The simulator's stand-in for the camera answers a touch anywhere on its view. High
        // enough to miss both the package's own "Select a custom image" button and the row that
        // rises from the bottom.
        app.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.22)).tap()

        let add: XCUIElement = try driver.waitForIdentifier(
            "e2e.scan.add",
            "la fiche du livre scanné",
            timeout: 45
        )

        // The row rises redacted while the edition is fetched, with its action disabled: waiting
        // for the button to become live is waiting for the *real* book rather than the
        // placeholder, so the title read below is the one that was filed.
        try driver.waitUntil("la résolution de l'édition scannée", timeout: 45) {
            add.exists && add.isEnabled
        }

        let title: String = driver.any("e2e.scan.title").label
        try driver.tap(add, "le bouton « + » du scan")

        try driver.waitUntil("la confirmation de l'ajout", timeout: 45) {
            driver.exists("e2e.scan.row") == false
        }
        return title.isEmpty ? "(titre illisible)" : title
    }

    /// One search, all the way to a copy in the inventory. Returns the title of the book added.
    @MainActor
    private static func searchAndAdd(
        query: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> String {
        try driver.openTab(.search)

        let field: XCUIElement = app.searchFields.firstMatch
        try driver.type(query, into: field, "le champ de recherche")

        try driver.waitUntil("les résultats sur inventaire.io", timeout: 45) {
            driver.all("e2e.searchResult").count > 0
        }

        let first: XCUIElement = driver.all("e2e.searchResult").element(boundBy: 0)
        try driver.tap(first, "le premier résultat de « \(query) »", until: {
            app.navigationBars.count > 0
        })

        try reachBookScreen(driver: driver)

        let title: String = driver.any("e2e.entityTitle").label
        try driver.tap(
            driver.any("e2e.book.menu"),
            "le menu « … » du livre",
            until: { driver.exists("e2e.book.addToInventory") }
        )
        try driver.tap(
            driver.any("e2e.book.addToInventory"),
            "« Ajouter à l'inventaire »",
            until: { app.staticTexts["Ajouté à votre inventaire"].exists }
        )

        // Back to the search field, ready for the next query.
        try driver.popBack(to: .search)
        return title.isEmpty ? query : title
    }

    /// Walks whatever a search result opened onto — an author, a work with several editions —
    /// down to the book screen, which is the only one that can add a copy.
    ///
    /// **It backtracks.** Which work a search returns first is inventaire.io's business and it
    /// changes; some of them have no edition at all, and their gateway sits on a spinner
    /// forever. So a branch that leads nowhere inside `patience` is abandoned — back one
    /// screen, next entry in the list — rather than reported as a broken app.
    @MainActor
    private static func reachBookScreen(driver: E2EDriver) throws {
        /// How long a pushed screen is given to produce something to act on before its branch
        /// is written off. Long enough for a work and its editions to arrive over the network.
        let patience: TimeInterval = 18
        let deadline: Date = .now.addingTimeInterval(150)
        /// Which entry of the current list to take. Raised each time a branch dead-ends or a row
        /// refuses to open, so the next attempt walks a different work.
        var candidate: Int = 0

        while Date.now < deadline {
            if driver.exists("e2e.book.menu") { return }

            let editions: XCUIElementQuery = driver.all("e2e.workEdition")
            if editions.count > 0 {
                let index: Int = min(candidate, editions.count - 1)
                if push(
                    editions.element(boundBy: index),
                    listIdentifier: "e2e.workEdition",
                    driver: driver
                ) {
                    continue
                }
                candidate += 1
                continue
            }

            let works: XCUIElementQuery = driver.all("e2e.authorWork")
            if works.count > 0 {
                let index: Int = min(candidate, works.count - 1)
                if push(
                    works.element(boundBy: index),
                    listIdentifier: "e2e.authorWork",
                    driver: driver
                ) {
                    continue
                }
                candidate += 1
                continue
            }

            // Nothing to act on: either the screen is still loading, or this branch is a work
            // with no edition behind it. Wait once, then back out and take the next entry.
            let arrived: Bool = driver.holds(
                {
                    driver.exists("e2e.book.menu")
                        || driver.all("e2e.workEdition").count > 0
                        || driver.all("e2e.authorWork").count > 0
                },
                within: patience
            )
            if arrived { continue }

            guard goBack(driver: driver) else { break }
            candidate += 1
        }

        throw E2EFailure(
            "Impossible d'atteindre l'écran du livre depuis ce résultat de recherche : "
            + "aucune des œuvres essayées n'a de fiche exploitable."
        )
    }

    /// Opens one row of a list, and says whether it actually left the list.
    ///
    /// **Two aims, because one is not enough here.** These rows are a `Button` whose label is a
    /// `NavigationLink` carrying a value nothing handles — the app's way of drawing a chevron —
    /// and a synthesised tap at the exact centre of that pair sometimes lands on the link, which
    /// does nothing at all. A second tap a third of the way in lands on the title instead. A row
    /// that refuses both is reported as refused, so the caller can try the next one rather than
    /// failing the whole search.
    @MainActor
    private static func push(
        _ row: XCUIElement,
        listIdentifier: String,
        driver: E2EDriver
    ) -> Bool {
        let opened: () -> Bool = {
            driver.exists("e2e.book.menu") || driver.exists(listIdentifier) == false
        }

        guard driver.isReachable(row) else { return false }

        row.tap()
        if driver.holds(opened, within: 12) { return true }

        guard driver.isReachable(row) else { return opened() }
        row.coordinate(withNormalizedOffset: .init(dx: 0.3, dy: 0.5)).tap()
        return driver.holds(opened, within: 12)
    }

    /// One step back up the stack, or `false` when there is nowhere to go.
    @MainActor
    private static func goBack(driver: E2EDriver) -> Bool {
        let back: XCUIElement = driver.app.navigationBars.buttons["BackButton"]
        guard driver.isReachable(back) else { return false }

        back.tap()
        driver.holds(
            {
                driver.all("e2e.authorWork").count > 0
                    || driver.all("e2e.workEdition").count > 0
            },
            within: 10
        )
        return true
    }

    /// Opens the inventory's book at `bookIndex` and files its work into `listName`.
    @MainActor
    private static func addBookToList(
        bookIndex: Int,
        listName: String,
        driver: E2EDriver,
        app: XCUIApplication
    ) throws -> String {
        try driver.openTab(.inventory)
        try driver.popBack(to: .inventory)

        let rows: XCUIElementQuery = driver.all("e2e.inventoryBook")
        guard rows.count > bookIndex else {
            throw E2EFailure("L'inventaire ne contient que \(rows.count) livre(s) affiché(s).")
        }

        try driver.tap(rows.element(boundBy: bookIndex), "le livre nº \(bookIndex + 1)", until: {
            driver.exists("e2e.book.menu")
        })

        let title: String = driver.any("e2e.entityTitle").label
        try driver.tap(
            driver.any("e2e.book.menu"),
            "le menu « … » du livre",
            until: { driver.exists("e2e.book.addToList") }
        )
        try driver.tap(
            driver.any("e2e.book.addToList"),
            "« Ajouter à une liste »",
            until: { app.alerts.buttons[listName].exists }
        )
        try driver.tap(
            app.alerts.buttons[listName],
            "la liste « \(listName) » dans le sélecteur",
            until: { app.alerts.buttons[listName].exists == false }
        )

        // An edition behind a single work opens a form for the comment; one behind several is
        // filed straight away. Both are correct, so both are accepted.
        let submit: XCUIElement = driver.any("e2e.listItemForm.submit")
        if submit.waitForExistence(timeout: 8) {
            try driver.tap(submit, "le bouton « Envoyer » du formulaire d'élément", until: {
                driver.exists("e2e.listItemForm.submit") == false
            })
        }

        try driver.popBack(to: .inventory)
        return title.isEmpty ? "livre nº \(bookIndex + 1)" : title
    }
}

/// The launch arguments `UITestHooks` reads, spelled out here because the test bundle does not
/// link the app target. Kept beside the scenario so the pair is obvious; the app's own copy is
/// the one that matters, and nothing but this comment holds the two together.
enum UITestHooksArguments {
    static let activation: String = "-uitest"
    static let reset: String = "-uitest-reset"
}
