package studio.lunabee.exlibris.backend.transactions

import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.bulkUpdate
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.newShelf
import studio.lunabee.exlibris.backend.items.shelfAction
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.items.visibleItems
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class TransactionItemEffectsRoutesTest {
    @Test
    fun `a loan holds the book busy once accepted and confirmed, frees it once returned, actions in order`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val itemId: String = client.newOfferedBook(owner)
                val transactionId: String = client.newTransaction(friend, itemId).id()

                val whileRequested: Boolean = isBusy(itemId, friend)
                client.moveTo(owner, transactionId, "accepted")
                val whileAccepted: Boolean = isBusy(itemId, friend)
                client.moveTo(friend, transactionId, "confirmed")
                val whileLent: Boolean = isBusy(itemId, owner)
                val returned: JsonObject = client.moveTo(owner, transactionId, "returned")

                assertFalse(whileRequested)
                assertTrue(whileAccepted)
                assertTrue(whileLent)
                assertFalse(isBusy(itemId, owner))
                assertEquals(listOf("requested", "accepted", "confirmed", "returned"), returned.actions())
                assertEquals(owner.id, client.visibleItems(listOf(itemId), owner).single().text("owner"))
            }
        }

    @Test
    fun `a loan cancelled, or declined, leaves the book not busy`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val cancelledItem: String = client.newOfferedBook(owner)
                val declinedItem: String = client.newOfferedBook(owner)
                val cancelled: String = client.newTransaction(friend, cancelledItem).id()
                val declined: String = client.newTransaction(friend, declinedItem).id()
                client.moveTo(owner, cancelled, "accepted")

                client.moveTo(friend, cancelled, "cancelled")
                client.moveTo(owner, declined, "declined")

                assertFalse(isBusy(cancelledItem, owner))
                assertFalse(isBusy(declinedItem, owner))
            }
        }

    @Test
    fun `a gift confirmed moves the book to the requester, private, off every étagère, counts following`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val giver: Reader = client.newReader()
                val receiver: Reader = client.newReader()
                client.befriend(giver, receiver)
                val itemId: String = client.newOfferedBook(giver, mode = "giving", details = "Annoté")
                client.bulkUpdate(giver, """{"ids":["$itemId"],"attribute":"notes","value":"Rien"}""")
                val shelfId: String = client.newShelf(giver)
                client.shelfAction(giver, "add-items", """{"id":"$shelfId","items":["$itemId"]}""")
                val giverBefore: Int = itemsCount(giver)
                val receiverBefore: Int = itemsCount(receiver)
                val transactionId: String = client.newTransaction(receiver, itemId).id()
                client.moveTo(giver, transactionId, "accepted")

                client.moveTo(receiver, transactionId, "confirmed")

                val item: JsonObject = client.visibleItems(listOf(itemId), receiver).single()
                assertEquals(receiver.id, item.text("owner"))
                assertEquals(emptyList(), item.strings("visibility"))
                assertEquals(emptyList(), item.strings("shelves"))
                assertEquals("inventorying", item.text("transaction"))
                assertNull(item["details"])
                assertNull(item["notes"])
                assertFalse(item.getValue("busy").jsonPrimitive.boolean)
                assertEquals(emptyList(), client.visibleItems(listOf(itemId), giver))
                assertEquals(giverBefore - 1, itemsCount(giver))
                assertEquals(receiverBefore + 1, itemsCount(receiver))
                assertEquals(0, countRows("SELECT count(*) FROM item_shelves WHERE shelf_id = '$shelfId'"))
            }
        }

    @Test
    fun `a sale confirmed moves the book too`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val seller: Reader = client.newReader()
                val buyer: Reader = client.newReader()
                client.befriend(seller, buyer)
                val itemId: String = client.newOfferedBook(seller, mode = "selling")
                val transactionId: String = client.newTransaction(buyer, itemId).id()
                client.moveTo(seller, transactionId, "accepted")

                client.moveTo(buyer, transactionId, "confirmed")

                assertEquals(buyer.id, client.visibleItems(listOf(itemId), buyer).single().text("owner"))
            }
        }

    private suspend fun ApplicationTestBuilder.isBusy(
        itemId: String,
        viewer: Reader,
    ): Boolean =
        client
            .visibleItems(listOf(itemId), viewer)
            .single()
            .getValue("busy")
            .jsonPrimitive.boolean

    /** The reader's own `items:count`, every section added, as `/api/user` answers it. */
    private suspend fun ApplicationTestBuilder.itemsCount(reader: Reader): Int {
        val snapshot: JsonObject =
            client
                .getAs("/api/user", reader)
                .json()
                .getValue("snapshot")
                .jsonObject
        return listOf("private", "network", "public").sumOf {
            snapshot
                .getValue(it)
                .jsonObject
                .getValue("items:count")
                .jsonPrimitive.int
        }
    }
}
