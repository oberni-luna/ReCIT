package studio.lunabee.nouveaurecit.data.transactions

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.w3c.dom.Element
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.ui.book.BookActionsState
import studio.lunabee.nouveaurecit.ui.book.BookMenuLine
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

/** The request worded by what the owner offers the copy for, and which copies are offered at all. */
class TransactionRequestWordingTest {
    /** `strings_transactions.xml`, read as the French a reader sees. The tests run from the module. */
    private val strings: Map<String, String> by lazy {
        val document = DocumentBuilderFactory.newInstance().newDocumentBuilder()
            .parse(File("src/main/res/values/strings_transactions.xml"))
        val nodes = document.getElementsByTagName("string")
        (0 until nodes.length).associate { index ->
            val element = nodes.item(index) as Element
            element.getAttribute("name") to element.textContent.replace("\\'", "'")
        }
    }

    private fun french(name: String, vararg args: String): String =
        args.foldIndexed(strings.getValue(name)) { index, text, arg -> text.replace("%${index + 1}\$s", arg) }

    @Test
    fun anInventoriedCopyHasNoWording() {
        assertNull(TransactionRequestWording.of(TransactionType.Inventorying))
        assertEquals(TransactionRequestWording.Lending, TransactionRequestWording.of(TransactionType.Lending))
        assertEquals(TransactionRequestWording.Selling, TransactionRequestWording.of(TransactionType.Selling))
        assertEquals(TransactionRequestWording.Giving, TransactionRequestWording.of(TransactionType.Giving))
    }

    @Test
    fun aLendingIsBorrowed() {
        val wording: TransactionRequestWording = TransactionRequestWording.Lending
        assertEquals(R.string.transaction_request_menu_lending, wording.menu)
        assertEquals("Emprunter à Anne", french("transaction_request_menu_lending", "Anne"))
        assertEquals("Emprunter Dune à Anne", french("transaction_request_title_lending", "Dune", "Anne"))
        assertEquals("Vous souhaitez l'emprunter à Anne", french("transaction_desc_requester_lending", "Anne"))
        assertEquals("Demander à l'emprunter", french("transaction_request_submit_lending"))
    }

    @Test
    fun aSaleIsBought() {
        val wording: TransactionRequestWording = TransactionRequestWording.Selling
        assertEquals(R.string.transaction_request_title_selling, wording.title)
        assertEquals("Acheter à Paul", french("transaction_request_menu_selling", "Paul"))
        assertEquals("Acheter Dune à Paul", french("transaction_request_title_selling", "Dune", "Paul"))
        assertEquals("Vous souhaitez l'acheter à Paul", french("transaction_desc_requester_selling", "Paul"))
        assertEquals("Demander à l'acheter", french("transaction_request_submit_selling"))
    }

    @Test
    fun aGiftIsPickedUp() {
        val wording: TransactionRequestWording = TransactionRequestWording.Giving
        assertEquals(R.string.transaction_desc_requester_giving, wording.sentence)
        assertEquals("Récupérer de Léa", french("transaction_request_menu_giving", "Léa"))
        assertEquals("Récupérer Dune de Léa", french("transaction_request_title_giving", "Dune", "Léa"))
        assertEquals("Vous souhaitez le récupérer de Léa", french("transaction_desc_requester_giving", "Léa"))
        assertEquals("Demander à le récupérer", french("transaction_request_submit_giving"))
    }

    @Test
    fun everyTypeHasItsOwnWordsEverywhere() {
        val entries: List<TransactionRequestWording> = TransactionRequestWording.entries
        listOf<(TransactionRequestWording) -> Int>({ it.menu }, { it.title }, { it.sentence }, { it.messageHint }, { it.submit })
            .forEach { field -> assertEquals(entries.size, entries.map(field).toSet().size) }
    }

    @Test
    fun theMessageIsRequired() {
        assertFalse(TransactionRequestWording.canSubmit(""))
        assertFalse(TransactionRequestWording.canSubmit("  \n"))
        assertTrue(TransactionRequestWording.canSubmit("Bonjour"))
    }

    private fun copy(id: String, owner: String?, type: TransactionType, ownerId: String = owner ?: "ghost"): ItemRow = ItemRow(
        item = InventoryItemEntity(
            id = id,
            rev = "1",
            editionUri = "isbn:1",
            transaction = type,
            visibility = emptyList(),
            ownerId = ownerId,
            created = 0.0,
        ),
        edition = null,
        owner = owner?.let { UserEntity(id = ownerId, username = it) },
    )

    @Test
    fun theTargetsAreTheCopiesOnOfferOnePerNamedOwner() {
        val targets: List<TransactionRequestTarget> = TransactionRequestTarget.of(
            listOf(
                copy("a1", "Anne", TransactionType.Lending),
                copy("a2", "Anne", TransactionType.Giving),
                copy("p1", "Paul", TransactionType.Inventorying),
                copy("x1", null, TransactionType.Selling),
                copy("l1", "Léa", TransactionType.Selling),
            ),
        )
        assertEquals(
            listOf(
                TransactionRequestTarget("a1", "Anne", TransactionRequestWording.Lending),
                TransactionRequestTarget("l1", "Léa", TransactionRequestWording.Selling),
            ),
            targets,
        )
    }

    @Test
    fun theMenuHoldsFiveOwnersAtMost() {
        val copies: List<ItemRow> = (1..7).map { copy("i$it", "Ami $it", TransactionType.Lending) }
        assertEquals(TransactionRequestTarget.MAX_TARGETS, TransactionRequestTarget.of(copies).size)
    }

    @Test
    fun theRequestsHeadSomeoneElsesSideOfTheMenuOnly() {
        val target = TransactionRequestTarget("a1", "Anne", TransactionRequestWording.Lending)
        val theirs = BookActionsState("isbn:1", myItemId = null, emptyList(), emptyList(), singleWorkUri = null, requests = listOf(target))
        assertEquals(listOf(BookMenuLine.Request(target), BookMenuLine.AddToInventory), theirs.lines)
        assertTrue(theirs.copy(myItemId = "mine").lines.none { it is BookMenuLine.Request })
    }

    @Test
    fun aRowAsksForItsOwnCopyOnly() {
        val state = BookActionsState(
            "isbn:1",
            myItemId = null,
            emptyList(),
            emptyList(),
            singleWorkUri = null,
            requests = listOf(TransactionRequestTarget("l1", "Léa", TransactionRequestWording.Selling)),
        )
        val annesRow: ItemRow = copy("a1", "Anne", TransactionType.Giving)
        assertEquals(listOf(TransactionRequestTarget("a1", "Anne", TransactionRequestWording.Giving)), state.forCopy(annesRow).requests)
        val mine: BookActionsState = state.copy(myItemId = "m1")
        assertTrue(mine.forCopy(copy("m1", "Moi", TransactionType.Lending)).requests.isEmpty())
    }

    @Test
    fun theServersRefusalsAreRecognised() {
        assertEquals(
            TransactionRequestFailure.ItemBusy,
            TransactionRequestFailure.from(NetworkError.BadStatus(403, """{"status_verbose":"item already busy"}""")),
        )
        assertEquals(
            TransactionRequestFailure.NotRequestable,
            TransactionRequestFailure.from(NetworkError.BadStatus(400, """{"status_verbose":"this item can't be requested"}""")),
        )
        assertEquals(TransactionRequestFailure.Other, TransactionRequestFailure.from(NetworkError.BadStatus(500, "")))
        assertEquals(TransactionRequestFailure.Other, TransactionRequestFailure.from(IllegalStateException()))
    }
}
