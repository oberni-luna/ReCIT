package studio.lunabee.nouveaurecit.e2e

import android.graphics.Point
import android.graphics.Rect
import android.os.Build
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.BySelector
import androidx.test.uiautomator.Configurator
import androidx.test.uiautomator.UiObject2
import androidx.test.uiautomator.Until
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.regex.Pattern

/**
 * The end-to-end scenario, Android side (feature 0065) — the iOS one (`ReCIT_iOS/UITests/
 * E2EScenarioTests.swift`, feature 0012) step for step, wherever the Android app has the screen:
 *
 * 1. sign in, then kill the app and start it again — still signed in;
 * 2. scan two books (the scanner reads [SCANNED_BOOKS] through the app's `E2EHooks` seam), finish the session;
 * 3. search four times from Recherche — a friend's copy among the local results, then one search per
 *    suggestion under « Chercher sur inventaire.io », adding a book from each of those three;
 * 4. open another edition of a book;
 * 5. « Ranger mes livres »: two new étagères, a book dragged onto each, « Enregistrer »;
 * 6. a list, two works in it, checked from the Listes tab;
 * 7. delete all of it — the list, the étagères, every book — and sign out.
 *
 * It signs into a real inventaire.io account and writes to it; every name it creates carries a
 * timestamp, so a run that died halfway cannot block the next one. Run it with
 * `scripts/e2e-android.sh`, which passes the credentials as instrumentation arguments.
 */
@RunWith(AndroidJUnit4::class)
class E2EScenarioTest {
    private lateinit var driver: E2EDriver
    private var keepsSession: Boolean = false
    private var stamp: String = LocalDateTime.now().format(DateTimeFormatter.ofPattern("MMdd-HHmmss"))

    @Test
    fun fullJourney() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val arguments = InstrumentationRegistry.getArguments()
        val username: String = arguments.getString("e2eUsername").orEmpty()
        val password: String = arguments.getString("e2ePassword").orEmpty()
        // For working on the scenario itself: start on the session already in the app, and keep it.
        keepsSession = arguments.getString("e2eKeepSession") == "true"
        // With e2eOnly, a run that died halfway can be finished: e2eStamp names what it created.
        arguments.getString("e2eStamp")?.let { stamp = it }
        // The welcome screen's wall of covers never stops moving, so the default ten seconds of
        // waiting for the screen to settle would be spent before every single lookup.
        Configurator.getInstance().waitForIdleTimeout = 500

        val directory = File(instrumentation.context.getExternalFilesDir(null), "e2e-report")
        driver = E2EDriver(
            instrumentation = instrumentation,
            report = E2EReport(directory, SCENARIO, deviceDescription(), username.ifEmpty { "?" }),
        )
        driver.barcodes = SCANNED_BOOKS.map(ScanTarget::barcode)

        try {
            play(username, password, only = arguments.getString("e2eOnly"))
        } finally {
            driver.report.finish()
        }
    }

    private fun play(username: String, password: String, only: String?) {
        val shelfNames: List<String> = listOf("E2E Romans $stamp", "E2E Poésie $stamp")
        val listName = "E2E Liste $stamp"

        driver.step("Lancement de l'application") {
            driver.launch(reset = !keepsSession)
            val landed: Int = driver.waitForAny("Au lancement", E2EDriver.NETWORK_TIMEOUT, button(SIGN_IN), tabBar())
            if (landed == 1) {
                if (!keepsSession) throw E2EFailure("L'app est connectée alors que ses données viennent d'être effacées.")
                return@step "session de l'app gardée (e2eKeepSession)"
            }
            "données de l'app effacées, écran d'accueil affiché"
        }

        driver.step("Connexion") {
            if (keepsSession && driver.exists(tabBar())) return@step "déjà connecté·e (e2eKeepSession)"
            if (username.isEmpty() || password.isEmpty()) {
                throw E2EFailure("Identifiants absents : lancez le scénario par scripts/e2e-android.sh.")
            }
            signIn(username, password)
            "connecté·e en tant que $username"
        }

        // Launching and signing in are always played: every other step needs them.
        driver.onlyStepsContaining = only

        driver.step("Redémarrage de l'application", critical = false) {
            driver.restartKeepingSession()
            val landed: Int = driver.waitForAny("Après le redémarrage", E2EDriver.NETWORK_TIMEOUT, tabBar(), button(CREATE_ACCOUNT))
            if (landed == 1) {
                // Repaired, so the steps behind are still played: the report keeps the KO.
                runCatching { signIn(username, password) }
                throw E2EFailure("La session n'a pas survécu au redémarrage : l'écran d'accueil est revenu.")
            }
            "toujours connecté·e après un arrêt forcé du processus"
        }

        driver.step("Ouverture du scanner") {
            openTab(TAB_INVENTORY)
            driver.tapUntil(button(SCAN), "Scanner") { driver.exists(By.res(SCAN_FEED)) }
            driver.waitFor(button(SCAN_FINISH), "le bouton « Terminer » du scanner")
            "scanner ouvert, ${SCANNED_BOOKS.size} codes-barres à lire"
        }

        SCANNED_BOOKS.forEachIndexed { offset, book ->
            driver.step("Scan du livre ${offset + 1}", critical = false) { scanOneBook(book) }
        }

        driver.step("Fin de la session de scan") {
            driver.tap(button(SCAN_FINISH), "Terminer")
            // The bilan only shows when the session added something; either way the tabs come back.
            val landed: Int = driver.waitForAny("Après « Terminer »", E2EDriver.DEFAULT_TIMEOUT, button(CONTINUE_WITHOUT_SORTING), tabBar())
            if (landed == 0) {
                driver.tapUntil(button(CONTINUE_WITHOUT_SORTING), CONTINUE_WITHOUT_SORTING) { !driver.exists(button(CONTINUE_WITHOUT_SORTING)) }
                driver.waitFor(tabBar(), "la barre d'onglets")
                "bilan affiché, « $CONTINUE_WITHOUT_SORTING »"
            } else {
                "pas de bilan : il ne vient que tant que le compte n'a aucune étagère"
            }
        }

        driver.step("Recherche 1 · « $FRIEND_BOOK_QUERY » chez mes ami·es", critical = false) {
            openTab(TAB_SEARCH)
            typeSearch(FRIEND_BOOK_QUERY)
            driver.waitFor(By.text(LOCAL_SECTION), "la section « $LOCAL_SECTION »")
            val copy: UiObject2 = driver.waitFor(
                By.clickable(true).hasDescendant(By.textStartsWith(OWNED_BY_PREFIX)).hasDescendant(By.textContains(FRIEND_BOOK_QUERY)),
                "l'exemplaire d'un·e ami·e parmi les résultats locaux",
            )
            val label: String = rowTitle(copy) ?: FRIEND_BOOK_QUERY
            val owner: String = copy.findObject(By.textStartsWith(OWNED_BY_PREFIX))?.text.orEmpty()
            copy.click()
            driver.waitFor(By.desc(BACK), "l'écran du livre")
            openTab(TAB_SEARCH)
            "« $label » — $owner"
        }

        SEARCHES.forEachIndexed { index, search ->
            driver.step("Recherche ${index + 2} · « ${search.query} »", critical = false) {
                openTab(TAB_SEARCH)
                typeSearch(search.query)
                driver.tap(
                    By.res("e2e.searchSuggestion.${search.suggestion}").hasDescendant(By.descContains(search.query)),
                    "la suggestion « ${search.suggestion} » pour « ${search.query} »",
                )
                val title: String = reachBookScreen(search.resultTag, search.query)
                val added: String = addToInventory()
                openTab(TAB_SEARCH)
                "« $title » — $added"
            }
        }

        driver.step("Autres éditions d'un livre", critical = false) {
            openTab(TAB_INVENTORY)
            val first: UiObject2 = driver.scrollTo(By.res(INVENTORY_ITEM), "un livre de l'inventaire")
            val title: String = rowTitle(first) ?: "?"
            first.click()
            driver.waitFor(By.desc(MORE), "l'écran du livre", E2EDriver.NETWORK_TIMEOUT)
            val row: UiObject2 = runCatching { driver.scrollTo(By.res(OTHER_EDITIONS), "« Autres éditions »", maxSwipes = 6) }.getOrNull()
                ?: run {
                    openTab(TAB_INVENTORY)
                    return@step "« $title » est la seule édition de son œuvre : rien à ouvrir"
                }
            row.click()
            driver.waitFor(By.res(WORK_EDITION), "une édition dans « Éditions de … »", E2EDriver.NETWORK_TIMEOUT * 2)
            val count: Int = driver.findAll(By.res(WORK_EDITION)).size
            openTab(TAB_INVENTORY)
            "« $title » : au moins $count éditions listées"
        }

        driver.step("Ouverture de l'écran de tri") {
            openTab(TAB_INVENTORY)
            driver.tapUntil(button(SORT), "Ranger") { driver.exists(By.text(SORT_TITLE)) }
            driver.waitFor(By.res(SORT_NEW_SHELF), "la tuile « Nouvelle étagère »", E2EDriver.NETWORK_TIMEOUT)
            val books: Int = driver.findAll(By.res(SORT_BOOK)).size
            "« $SORT_TITLE », $books livres à ranger visibles"
        }

        shelfNames.forEach { name ->
            driver.step("Création de l'étagère « $name »", critical = false) {
                revealInSortGrid(By.res(SORT_NEW_SHELF), "la tuile « Nouvelle étagère »")
                driver.tapUntil(By.res(SORT_NEW_SHELF), "la tuile « Nouvelle étagère »") { driver.exists(By.clazz(E2EDriver.EDIT_TEXT)) }
                driver.type(driver.textField(0, "Nom de l'étagère"), name, "Nom de l'étagère")
                driver.tap(button(CREATE), CREATE)
                driver.waitFor(By.res("$SORT_SHELF_PREFIX$name"), "la carte de l'étagère « $name »")
                "étagère créée sur la surface, pas encore enregistrée"
            }
        }

        shelfNames.forEach { name ->
            driver.step("Glisser-déposer d'un livre sur « $name »", critical = false) {
                val book: UiObject2 = driver.waitFor(By.res(SORT_BOOK), "un livre à ranger")
                val title: String = book.findObject(By.clazz(TEXT_VIEW))?.text ?: "?"
                val card: UiObject2 = revealInSortGrid(By.res("$SORT_SHELF_PREFIX$name"), "la carte « $name »")
                val from: Rect = book.visibleBounds
                val to: Rect = card.visibleBounds
                // The cover is the drag handle, and it sits in the top half of the cell.
                driver.longPressDrag(Point(from.centerX(), from.top + from.height() / 3), Point(to.centerX(), to.centerY()))
                driver.waitUntil("« $title » posé sur « $name »") {
                    driver.find(By.res("$SORT_SHELF_PREFIX$name"))?.findObject(By.textStartsWith("$name ·")) != null
                }
                "« $title »"
            }
        }

        driver.step("Application du rangement", critical = false) {
            driver.tap(button(SAVE), SAVE)
            // The footer turns into the run's report: « 2 étagères ont été enregistrées. », or why it stopped.
            val report: UiObject2 = driver.waitFor(
                By.text(Pattern.compile(".*(a|ont) été enregistrées?.*|L'enregistrement s'est arrêté.*", Pattern.DOTALL)),
                "le compte-rendu de l'enregistrement",
                E2EDriver.NETWORK_TIMEOUT,
            )
            if (report.text.startsWith("L'enregistrement")) throw E2EFailure(report.text)
            report.text
        }

        driver.step("Fermeture de l'écran de tri", critical = false) {
            driver.tap(By.desc(CLOSE), CLOSE)
            if (driver.exists(button(LEAVE))) driver.tap(button(LEAVE), LEAVE)
            driver.waitFor(tabBar(), "la barre d'onglets")
            "retour à l'inventaire"
        }

        driver.step("Création de la liste « $listName »", critical = false) {
            openTab(TAB_LISTS)
            driver.tap(By.desc(ADD), "le « + » des listes")
            driver.waitFor(By.text(LIST_FORM_TITLE), "le formulaire « $LIST_FORM_TITLE »")
            driver.type(driver.textField(0, "Nom"), listName, "Nom de la liste")
            driver.tap(button(CREATE), CREATE)
            driver.waitGone(By.text(LIST_FORM_TITLE), "le formulaire")
            driver.waitFor(By.text(listName), "la liste dans l'onglet Listes", E2EDriver.NETWORK_TIMEOUT)
            "liste d'œuvres"
        }

        repeat(LIST_WORK_COUNT) { index ->
            driver.step("Ajout de l'œuvre ${index + 1} à la liste", critical = false) { addBookToList(index, listName) }
        }

        driver.step("Vérification du contenu de la liste", critical = false) {
            openTab(TAB_LISTS)
            val row: UiObject2 = driver.waitFor(By.clickable(true).hasDescendant(By.text(listName)), "la liste « $listName »")
            val count: String = row.findObject(By.textContains("œuvre"))?.text
                ?: throw E2EFailure("La ligne de « $listName » ne dit pas combien d'œuvres elle contient.")
            if (!count.startsWith("$LIST_WORK_COUNT")) throw E2EFailure("« $listName » annonce « $count », $LIST_WORK_COUNT attendues.")
            count
        }

        driver.step("Suppression de la liste", critical = false) {
            openTab(TAB_LISTS)
            val row: UiObject2 = driver.waitFor(By.clickable(true).hasDescendant(By.text(listName)), "la liste « $listName »")
            val bounds: Rect = row.visibleBounds
            // Not from the edge: a swipe that starts there is the system's back gesture, and leaves the app.
            driver.device.swipe(bounds.width() * 4 / 5, bounds.centerY(), bounds.width() / 6, bounds.centerY(), 20)
            driver.waitGone(By.text(listName), "la liste « $listName »", E2EDriver.NETWORK_TIMEOUT)
            "balayée vers la gauche, supprimée"
        }

        shelfNames.forEach { name ->
            driver.step("Suppression de l'étagère « $name »", critical = false) {
                openTab(TAB_INVENTORY)
                val card: UiObject2 = findShelfInCarousel(name)
                card.click()
                // A tap made while the étagère's screen is still sliding in is lost: tap until the sheet shows.
                driver.waitFor(By.desc(EDIT), "le crayon « $EDIT »", E2EDriver.NETWORK_TIMEOUT)
                driver.tapUntil(By.desc(EDIT), "le crayon « $EDIT »") { driver.exists(By.text(SHELF_FORM_TITLE)) }
                driver.scrollTo(button(DELETE_SHELF), DELETE_SHELF).click()
                driver.tap(button(DELETE), DELETE)
                driver.waitFor(tabBar(), "le retour à l'inventaire", E2EDriver.NETWORK_TIMEOUT)
                driver.waitUntil("« $name » retirée du carrousel") { !driver.exists(By.text(name)) }
                "supprimée depuis « $EDIT »"
            }
        }

        driver.step("Suppression des livres de l'inventaire", critical = false) {
            openTab(TAB_INVENTORY)
            val removed: MutableList<String> = mutableListOf()
            repeat(MAX_BOOKS_TO_REMOVE) {
                val row: UiObject2 = runCatching { driver.scrollTo(By.res(INVENTORY_ITEM), "un livre", maxSwipes = 3) }.getOrNull()
                    ?: return@step "${removed.size} livres supprimés : ${removed.joinToString(", ")}"
                val title: String = rowTitle(row) ?: "?"
                row.click()
                driver.tap(By.desc(MORE), "le menu « … » du livre", E2EDriver.NETWORK_TIMEOUT)
                driver.tap(By.text(REMOVE_BOOK), REMOVE_BOOK)
                driver.tap(button(DELETE), DELETE)
                driver.waitFor(tabBar(), "le retour à l'inventaire", E2EDriver.NETWORK_TIMEOUT)
                removed += title
                SystemClock.sleep(SETTLE_MILLIS)
            }
            throw E2EFailure("Encore des livres après $MAX_BOOKS_TO_REMOVE suppressions : ${removed.joinToString(", ")}")
        }

        if (keepsSession) {
            driver.skip("Déconnexion", "Session gardée (e2eKeepSession).")
            return
        }
        driver.step("Déconnexion", critical = false) {
            openTab(TAB_INVENTORY)
            driver.tap(By.desc(PROFILE), "l'avatar du profil")
            driver.scrollTo(By.text(LOGOUT), LOGOUT).click()
            driver.waitFor(button(CREATE_ACCOUNT), "l'écran d'accueil", E2EDriver.NETWORK_TIMEOUT)
            "retour à l'écran d'accueil"
        }
    }

    // ------------------------------------------------------------------------------------- journeys

    private fun signIn(username: String, password: String) {
        driver.tapUntil(button(SIGN_IN), SIGN_IN) { driver.exists(By.text(LOGIN_SUBTITLE)) }
        driver.type(driver.textField(0, "Nom d'utilisateur·ice"), username, "Nom d'utilisateur·ice")
        driver.type(driver.textField(1, "Mot de passe"), password, "Mot de passe")
        driver.tap(button(SIGN_IN), SIGN_IN)
        val landed: Int = driver.waitForAny(
            "Après « Se connecter »",
            E2EDriver.NETWORK_TIMEOUT,
            tabBar(),
            By.text(Pattern.compile("(Nom d'utilisateur·ice ou mot de passe incorrect|Impossible de joindre|Une erreur est survenue).*")),
        )
        if (landed == 1) {
            val said: String = driver.find(By.text(Pattern.compile("(Nom d'utilisateur·ice|Impossible|Une erreur).*")))?.text.orEmpty()
            throw E2EFailure("Connexion refusée : « $said » (inventaire.io limite les connexions : attendez quelques minutes).")
        }
    }

    /**
     * Waits for the row the seam's barcode brings up — recognised by [book]'s title, since the row
     * before it may still be clearing — files it, and says what it was.
     */
    private fun scanOneBook(book: ScanTarget): String {
        // The seam's feed brings the next barcode when it is touched.
        driver.tap(By.res(SCAN_FEED), "l'image du scanner")
        val title: BySelector = By.textContains(book.title)
        var outcome: String? = null
        driver.waitUntil("La ligne de « ${book.title} » (${book.barcode})", E2EDriver.NETWORK_TIMEOUT) {
            when {
                driver.exists(By.text(book.barcode)) && driver.exists(By.text(SCAN_NOT_FOUND)) ->
                    throw E2EFailure("inventaire.io ne connaît pas l'édition ${book.barcode}.")
                !driver.exists(title) -> false
                driver.exists(By.text(SCAN_OWNED)) -> {
                    outcome = "déjà dans l'inventaire"
                    true
                }
                driver.exists(By.desc(ADD_TO_INVENTORY).enabled(true)) -> {
                    driver.find(By.desc(ADD_TO_INVENTORY))?.click()
                    outcome = "ajouté"
                    true
                }
                else -> false
            }
        }
        // The next barcode only comes once this row has cleared.
        driver.waitGone(title, "la ligne de « ${book.title} »", E2EDriver.NETWORK_TIMEOUT)
        return "« ${book.title} » (${book.barcode}) $outcome"
    }

    /**
     * Types the query, and types it again until it sticks: the field takes the focus as the tab opens,
     * the keyboard comes up with it, and its autocorrection turns « Woolf » into « Wolf » behind our back.
     */
    private fun typeSearch(query: String) {
        driver.waitUntil("« $query » dans le champ de recherche") {
            val field: UiObject2 = driver.textField(0, "Rechercher")
            if (field.text != query) driver.type(field, query, "Rechercher")
            SystemClock.sleep(SETTLE_MILLIS)
            driver.textField(0, "Rechercher").text == query
        }
    }

    /**
     * Opens the results under [resultTag] one after the other until one lands on a book screen. A
     * work with no edition behind it says so; an author's screen is walked into its first works.
     */
    private fun reachBookScreen(resultTag: String, query: String): String {
        driver.waitFor(By.res(resultTag), "un résultat sur inventaire.io", E2EDriver.NETWORK_TIMEOUT)
        val isAuthorSearch: Boolean = resultTag == HUMAN_RESULT
        val tried: MutableSet<String> = mutableSetOf()
        var swipes = 0
        while (tried.size < MAX_RESULTS_TRIED && swipes <= MAX_RESULT_SWIPES) {
            // A row read while the list recomposes goes stale under our feet: read the list again.
            val rows: List<UiObject2> = runCatching {
                driver.findAll(By.res(resultTag))
                    .filter { rowKey(it) !in tried }
                    .sortedBy { it.visibleBounds.top }
            }.getOrElse {
                SystemClock.sleep(SETTLE_MILLIS)
                continue
            }
            // inventaire.io ranks Victor Hugo's daughter above him: for a person, the exact name first,
            // looked for further down before settling for the others.
            val result: UiObject2? = if (isAuthorSearch) {
                rows.firstOrNull { rowTitle(it).equals(query, ignoreCase = true) }
                    ?: rows.firstOrNull().takeIf { swipes == MAX_RESULT_SWIPES }
            } else {
                rows.firstOrNull()
            }
            if (result == null) {
                driver.swipeUp(resultsArea())
                swipes += 1
                continue
            }
            val label: String = rowTitle(result) ?: "?"
            tried += rowKey(result)
            result.click()
            if (isAuthorSearch) {
                walkAuthorWorks()?.let { return "$it, de $label" }
            } else if (landsOnBook()) {
                return label
            }
            driver.back()
        }
        throw E2EFailure("Aucun des ${tried.size} résultats essayés n'a mené à une édition.")
    }

    private fun rowKey(row: UiObject2): String = row.findObjects(By.clazz(TEXT_VIEW)).joinToString("|") { it.text.orEmpty() }

    private fun resultsArea(): Rect = Rect(0, driver.device.displayHeight / 4, driver.device.displayWidth, driver.device.displayHeight * 3 / 4)

    /** An author·ice's works open « Éditions de … »: the first work with an edition there leads to a book. */
    private fun walkAuthorWorks(): String? {
        val found: Boolean = runCatching { driver.waitFor(By.res(AUTHOR_WORK), "une œuvre de l'auteur·ice", E2EDriver.NETWORK_TIMEOUT) }.isSuccess
        if (!found) return null
        repeat(MAX_RESULTS_TRIED) { index ->
            val work: UiObject2 = driver.findAll(By.res(AUTHOR_WORK)).sortedBy { it.visibleBounds.top }.getOrNull(index) ?: return null
            work.click()
            val edition: UiObject2? = runCatching {
                driver.waitFor(By.res(WORK_EDITION), "une édition de l'œuvre", E2EDriver.NETWORK_TIMEOUT)
            }.getOrNull()
            if (edition != null) {
                val title: String = rowTitle(edition) ?: "?"
                edition.click()
                if (landsOnBook()) return title
                driver.back()
            }
            driver.back()
        }
        return null
    }

    /**
     * Whether the screen just pushed is a book with its « … » menu, rather than an absence. « Plus »
     * alone is not enough: « Éditions de … » has one too.
     */
    private fun landsOnBook(): Boolean {
        var isBook = false
        driver.waitUntil("L'écran du livre", E2EDriver.NETWORK_TIMEOUT) {
            isBook = driver.exists(By.res(BOOK)) && driver.exists(By.desc(MORE))
            isBook || driver.exists(By.text(NO_EDITION)) || driver.exists(By.textStartsWith(RESOLVE_FAILED))
        }
        return isBook
    }

    /** « … » › « Ajouter à l'inventaire », or nothing if the menu offers the deletion instead. */
    private fun addToInventory(): String {
        driver.tap(By.desc(MORE), "le menu « … » du livre")
        val landed: Int = driver.waitForAny("Le menu du livre", E2EDriver.DEFAULT_TIMEOUT, By.text(ADD_TO_INVENTORY), By.text(REMOVE_BOOK))
        if (landed == 1) {
            driver.back()
            return "déjà dans l'inventaire"
        }
        driver.tap(By.text(ADD_TO_INVENTORY), ADD_TO_INVENTORY)
        driver.waitFor(By.text(ADDED), "« $ADDED »", E2EDriver.NETWORK_TIMEOUT)
        return ADDED
    }

    /** « … » › « Liste » › « Ajouter à <list> », on the [index]-th book of the inventory. */
    private fun addBookToList(index: Int, listName: String): String {
        openTab(TAB_INVENTORY)
        driver.scrollTo(By.res(INVENTORY_ITEM), "un livre de l'inventaire")
        val row: UiObject2 = driver.findAll(By.res(INVENTORY_ITEM)).sortedBy { it.visibleBounds.top }.getOrNull(index)
            ?: throw E2EFailure("L'inventaire n'a pas ${index + 1} livres à mettre dans la liste.")
        val title: String = rowTitle(row) ?: "?"
        row.click()
        driver.tap(By.desc(MORE), "le menu « … » du livre", E2EDriver.NETWORK_TIMEOUT)
        driver.tap(By.text(MENU_LIST), "« $MENU_LIST »")
        driver.tap(By.text("Ajouter à $listName"), "« Ajouter à $listName »")
        driver.waitFor(By.text(Pattern.compile("Ajouté à .*")), "la confirmation de l'ajout", E2EDriver.NETWORK_TIMEOUT)
        openTab(TAB_INVENTORY)
        return "« $title »"
    }

    /**
     * The carousel snaps one étagère to the middle, and only that one's label is exposed. A slow swipe
     * across two thirds of the screen, just above the labels — over the plank and the cards' foot; neither
     * the labels nor the space above the cards scroll it — moves it by exactly one card; it is swiped one card at a time, to one end, then to the other,
     * until [name] is the one in the middle.
     */
    private fun findShelfInCarousel(name: String): UiObject2 {
        val labelTop: Int = driver.waitFor(By.text(LABEL_BULLET), "l'étiquette d'une étagère").visibleBounds.top
        val y: Int = labelTop - driver.device.displayHeight / 12
        val width: Int = driver.device.displayWidth
        val reach: Int = width * 2 / 3
        centredLabel(name)?.let { return it }
        for (direction in listOf(1, -1)) {
            repeat(MAX_CAROUSEL_SWIPES) {
                driver.device.swipe(width / 2 + direction * reach / 2, y, width / 2 - direction * reach / 2, y, CAROUSEL_SWIPE_STEPS)
                SystemClock.sleep(SETTLE_MILLIS)
                centredLabel(name)?.let { return it }
            }
        }
        throw E2EFailure("« $name » est introuvable dans le carrousel des étagères.")
    }

    /** [name]'s label, if its card is the one snapped in the middle. A label read mid-snap goes stale: none. */
    private fun centredLabel(name: String): UiObject2? = runCatching {
        driver.find(By.text(name))?.takeIf { kotlin.math.abs(it.visibleBounds.centerX() - driver.device.displayWidth / 2) < driver.device.displayWidth / 6 }
    }.getOrNull()

    // ----------------------------------------------------------------------------------- navigation

    /**
     * Opens a tab at its root — also the way back to a tab's root, since a tap on the selected tab pops
     * its stack: a back press made while the screen being left is still animating out finds its
     * « Retour » again, and one back too many leaves the app.
     *
     * The tab bar's label is tapped, the lowest of the words on screen. The item itself is no use: the
     * selected one reports `clickable = false`, though a tap on it still pops its stack.
     */
    private fun openTab(title: String) {
        uncoverTabBar()
        repeat(2) {
            driver.waitFor(tabBar(), "la barre d'onglets")
            val label: UiObject2 = driver.findAll(By.text(title)).maxByOrNull { it.visibleBounds.top }
                ?: run {
                    uncoverTabBar()
                    driver.findAll(By.text(title)).maxByOrNull { it.visibleBounds.top }
                }
                ?: throw E2EFailure("L'onglet « $title » est introuvable.")
            label.click()
            driver.device.waitForIdle(1_500)
        }
    }

    /**
     * A menu, sheet or dialog a failed step left open is a window of its own, and UI Automator then sees
     * nothing else — the tab bar included. Back closes it; back is only pressed while the bar is hidden,
     * since at a tab's root it would leave the app.
     */
    private fun uncoverTabBar() {
        repeat(4) {
            if (driver.device.wait(Until.hasObject(tabBar()), 2_000)) return
            if (!driver.isAppInForeground() || !driver.isCovered()) return
            driver.back()
        }
    }

    private fun sortGridArea(): Rect = Rect(0, driver.device.displayHeight / 6, driver.device.displayWidth, driver.device.displayHeight / 2)

    /**
     * Scrolls the étagères' grid until [selector] sits whole above the anchored « Livres à ranger »
     * panel. The grid runs on under the panel, and a card found there is tapped through it.
     */
    private fun revealInSortGrid(selector: BySelector, what: String): UiObject2 {
        repeat(MAX_GRID_SWIPES) {
            val panelTop: Int = driver.find(By.textStartsWith(UNSHELVED_HEADER))?.visibleBounds?.top ?: driver.device.displayHeight
            val element: UiObject2? = driver.find(selector)
            if (element != null && element.visibleBounds.bottom < panelTop && element.visibleBounds.height() > MIN_CARD_HEIGHT) {
                // Let the fling settle: a tap on a grid still moving is taken for a stop, not a tap.
                SystemClock.sleep(SETTLE_MILLIS)
                return driver.find(selector) ?: element
            }
            // Down the grid while the element is not there yet or under the panel; back up if it is cut at the top.
            if (element != null && element.visibleBounds.top <= sortGridArea().top) {
                val x: Int = driver.device.displayWidth / 2
                driver.device.swipe(x, sortGridArea().top, x, sortGridArea().bottom, 25)
            } else {
                driver.swipeUp(sortGridArea())
            }
        }
        throw E2EFailure("« $what » n'a pas pu être amenée au-dessus du panneau « Livres à ranger ».")
    }


    // ------------------------------------------------------------------------------------- reading

    /** A row's title: its first line of text. */
    private fun rowTitle(row: UiObject2): String? = row.findObjects(By.clazz(TEXT_VIEW))
        .sortedBy { it.visibleBounds.top }
        .firstOrNull { !it.text.isNullOrBlank() }
        ?.text

    private fun deviceDescription(): String =
        "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

    /**
     * A Compose button, by its label. The label is not the clickable node, but a tap on it lands on
     * the button; asking for the clickable node *holding* the label instead can match a sheet or a
     * dialog that holds it too, and the tap then lands in the middle of that.
     */
    private fun button(text: String): BySelector = By.text(text)

    /** The tab bar, by the one tab no other screen names. */
    private fun tabBar(): BySelector = By.text(TAB_NETWORK)

    private data class ScanTarget(val barcode: String, val title: String)

    private data class Search(val query: String, val suggestion: String, val resultTag: String)

    private companion object {
        const val SCENARIO: String = "Ex-libris Android — parcours complet"

        /** The two books the iOS scenario scans. */
        val SCANNED_BOOKS: List<ScanTarget> = listOf(
            ScanTarget("9782370493002", "Lucioles"),
            ScanTarget("9782413013518", "Penss et les plis du monde"),
        )

        const val FRIEND_BOOK_QUERY: String = "Dans la forêt"
        val SEARCHES: List<Search> = listOf(
            Search("Victor Hugo", "humans", HUMAN_RESULT),
            Search("Virginia Woolf", "everything", "e2e.searchResult.works"),
            Search("Des souris et des hommes", "works", "e2e.searchResult.works"),
        )
        const val LIST_WORK_COUNT: Int = 2
        const val MAX_RESULTS_TRIED: Int = 5
        const val MAX_RESULT_SWIPES: Int = 3
        const val HUMAN_RESULT: String = "e2e.searchResult.humans"
        const val MAX_BOOKS_TO_REMOVE: Int = 40
        const val MAX_CAROUSEL_SWIPES: Int = 15
        const val CAROUSEL_SWIPE_STEPS: Int = 100
        const val MAX_GRID_SWIPES: Int = 12
        const val MIN_CARD_HEIGHT: Int = 200
        const val SETTLE_MILLIS: Long = 1_000

        const val TEXT_VIEW: String = "android.widget.TextView"

        // Tabs
        const val TAB_INVENTORY: String = "Inventaire"
        const val TAB_LISTS: String = "Listes"
        const val TAB_SEARCH: String = "Recherche"
        const val TAB_NETWORK: String = "Réseau"

        // Words on screen
        const val SIGN_IN: String = "Se connecter"
        const val CREATE_ACCOUNT: String = "Créer un compte"
        const val LOGIN_SUBTITLE: String = "Connectez-vous à votre compte inventaire.io."
        const val SCAN: String = "Scanner"
        const val SCAN_FINISH: String = "Terminer"
        const val SCAN_OWNED: String = "Dans mon inventaire"
        const val SCAN_NOT_FOUND: String = "Cette édition n'existe pas sur inventaire.io"
        const val ADD_TO_INVENTORY: String = "Ajouter à l'inventaire"
        const val ADDED: String = "Ajouté à votre inventaire"
        const val CONTINUE_WITHOUT_SORTING: String = "Continuer sans ranger"
        const val LOCAL_SECTION: String = "Dans mes livres et chez mes ami·es"
        const val OWNED_BY_PREFIX: String = "Appartient à"
        const val NO_EDITION: String = "Aucune édition pour ce livre"
        const val RESOLVE_FAILED: String = "La connexion à inventaire.io a échoué"
        const val REMOVE_BOOK: String = "Supprimer ce livre"
        const val MENU_LIST: String = "Liste"
        const val SORT: String = "Ranger"
        const val SORT_TITLE: String = "Ranger mes livres"
        const val UNSHELVED_HEADER: String = "Livres à ranger"
        const val CREATE: String = "Créer"
        const val SAVE: String = "Enregistrer"
        const val LEAVE: String = "Quitter"
        const val LIST_FORM_TITLE: String = "Créer une liste"
        const val SHELVES_SECTION: String = "Étagères"
        const val LABEL_BULLET: String = "•"
        const val EDIT: String = "Modifier"
        const val DELETE_SHELF: String = "Supprimer l'étagère"
        const val SHELF_FORM_TITLE: String = "Modifier l'étagère"
        const val DELETE: String = "Supprimer"
        const val LOGOUT: String = "Se déconnecter"

        // Content descriptions
        const val BACK: String = "Retour"
        const val MORE: String = "Plus"
        const val CLOSE: String = "Fermer"
        const val ADD: String = "Ajouter"
        const val PROFILE: String = "Profil"

        // Test tags (resource ids)
        const val SCAN_FEED: String = "e2e.scan.feed"
        const val INVENTORY_ITEM: String = "e2e.inventory.item"
        const val BOOK: String = "e2e.book"
        const val OTHER_EDITIONS: String = "e2e.book.otherEditions"
        const val WORK_EDITION: String = "e2e.workEdition"
        const val AUTHOR_WORK: String = "e2e.authorWork"
        const val SORT_NEW_SHELF: String = "e2e.sortNewShelf"
        const val SORT_BOOK: String = "e2e.sortBook"
        const val SORT_SHELF_PREFIX: String = "e2e.sortShelf."
    }
}
