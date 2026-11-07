package studio.lunabee.exlibris.backend.transactions

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.deleteAs
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class TransactionsAccountDeletionRoutesTest {
    @Test
    fun `the owner gone, the requester keeps the finished Échange by its snapshot and sees the open one cancelled`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val finished: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()
                client.moveTo(owner, finished, "declined")
                val open: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()
                client.moveTo(owner, open, "accepted")
                client.postMessage(owner, open, "À samedi")

                assertEquals(HttpStatusCode.OK, client.deleteAs("/api/user", owner).status)

                val left: Map<String, JsonObject> = client.transactionsOf(friend).associateBy { it.id() }
                assertEquals(setOf(finished, open), left.keys)
                assertEquals("declined", left.getValue(finished).text("state"))
                assertEquals(
                    "1984",
                    left
                        .getValue(finished)
                        .getValue("snapshot")
                        .jsonObject
                        .getValue("entity")
                        .jsonObject
                        .text("title"),
                )
                assertEquals("cancelled", left.getValue(open).text("state"))
                assertEquals(listOf("requested", "accepted", "cancelled"), left.getValue(open).actions())
                assertEquals(
                    listOf(friend.id, owner.id),
                    client.messagesOf(friend, open).map { it.text("user") },
                )
            }
        }

    @Test
    fun `the requester gone, a confirmed loan is cancelled, and once both are gone nothing is left`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()
                client.moveTo(owner, transactionId, "accepted")
                client.moveTo(friend, transactionId, "confirmed")

                client.deleteAs("/api/user", friend)
                val afterRequester: JsonObject = client.transactionsOf(owner).single()
                client.deleteAs("/api/user", owner)

                assertEquals("cancelled", afterRequester.text("state"))
                assertEquals(0, countRows("SELECT count(*) FROM transactions WHERE id = '$transactionId'"))
                assertEquals(
                    0,
                    countRows("SELECT count(*) FROM transaction_messages WHERE transaction_id = '$transactionId'"),
                )
            }
        }
}
