package studio.lunabee.exlibris.backend.transactions

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.groups.putJson
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class TransactionStateRoutesTest {
    @Test
    fun `the owner accepts, the requester may not and gets inventaire's error`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val (owner: Reader, friend: Reader, transactionId: String) = requested()

                val byRequester: HttpResponse = client.updateState(friend, transactionId, "accepted")
                val byOwner: HttpResponse = client.updateState(owner, transactionId, "accepted")

                assertEquals(HttpStatusCode.Forbidden, byRequester.status)
                assertMatchesFixture("transactions/wrong-user.derived.json", byRequester.bodyAsText())
                assertEquals(HttpStatusCode.OK, byOwner.status, byOwner.bodyAsText())
                assertMatchesFixture("transactions/update-state.derived.json", byOwner.bodyAsText())
                val transaction: JsonObject = byOwner.json().getValue("transaction").jsonObject
                assertTransactionShape("transactions/update-state.derived.json", transaction)
                assertEquals("accepted", transaction.text("state"))
                assertEquals(listOf("requested", "accepted"), transaction.actions())
                assertTrue(transaction.read("owner"))
                assertFalse(transaction.read("requester"))
                assertTrue(transaction.text("_rev").startsWith("2-"))
            }
        }

    @Test
    fun `the owner declines, and nothing follows a declined Échange`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val (owner: Reader, friend: Reader, transactionId: String) = requested()

                client.moveTo(owner, transactionId, "declined")
                val afterwards: HttpResponse = client.updateState(owner, transactionId, "accepted")
                val requesterDeclines: HttpResponse = client.updateState(friend, transactionId, "declined")

                assertEquals(HttpStatusCode.BadRequest, afterwards.status)
                assertMatchesFixture("transactions/invalid-state-update.derived.json", afterwards.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, requesterDeclines.status)
            }
        }

    @Test
    fun `either side cancels, and the action names who did`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val (owner: Reader, friend: Reader, requestedId: String) = requested()
                val acceptedId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()
                client.moveTo(owner, acceptedId, "accepted")

                val byRequester: HttpResponse = client.updateState(friend, requestedId, "cancelled")
                val byOwner: JsonObject = client.moveTo(owner, acceptedId, "cancelled")

                assertMatchesFixture("transactions/update-state.cancelled.derived.json", byRequester.bodyAsText())
                val cancelled: JsonObject = byRequester.json().getValue("transaction").jsonObject
                assertTransactionShape("transactions/update-state.cancelled.derived.json", cancelled)
                assertEquals("requester", cancelled.lastAction().text("actor"))
                assertEquals("owner", byOwner.lastAction().text("actor"))
                assertNull(byOwner.getValue("actions").jsonArray[1].jsonObject["actor"])
            }
        }

    @Test
    fun `the requester confirms an accepted Échange, not a requested one, and the owner may not`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val (owner: Reader, friend: Reader, transactionId: String) = requested()

                val tooSoon: HttpResponse = client.updateState(friend, transactionId, "confirmed")
                client.moveTo(owner, transactionId, "accepted")
                val byOwner: HttpResponse = client.updateState(owner, transactionId, "confirmed")
                val confirmed: JsonObject = client.moveTo(friend, transactionId, "confirmed")

                assertEquals(HttpStatusCode.BadRequest, tooSoon.status)
                assertEquals(HttpStatusCode.Forbidden, byOwner.status)
                assertEquals(listOf("requested", "accepted", "confirmed"), confirmed.actions())
                assertFalse(confirmed.read("owner"))
            }
        }

    @Test
    fun `only a loan is returned, by its owner, and a confirmed one may still be cancelled`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val gift: String = confirmed(owner, friend, "giving")
                val loan: String = confirmed(owner, friend, "lending")
                val otherLoan: String = confirmed(owner, friend, "lending")

                val giftReturned: HttpResponse = client.updateState(owner, gift, "returned")
                val returnedByBorrower: HttpResponse = client.updateState(friend, loan, "returned")
                val returned: JsonObject = client.moveTo(owner, loan, "returned")
                val cancelled: JsonObject = client.moveTo(friend, otherLoan, "cancelled")

                assertEquals(HttpStatusCode.BadRequest, giftReturned.status)
                assertMatchesFixture("transactions/state-mismatch.derived.json", giftReturned.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, returnedByBorrower.status)
                assertEquals("returned", returned.text("state"))
                assertEquals("cancelled", cancelled.text("state"))
            }
        }

    @Test
    fun `accepting a second request while the book is held answers item already busy`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val other: Reader = client.newReader()
                client.befriend(owner, friend)
                client.befriend(owner, other)
                val itemId: String = client.newOfferedBook(owner)
                val first: String = client.newTransaction(friend, itemId).id()
                val second: String = client.newTransaction(other, itemId).id()
                client.moveTo(owner, first, "accepted")

                val response: HttpResponse = client.updateState(owner, second, "accepted")

                assertEquals(HttpStatusCode.Forbidden, response.status)
                assertMatchesFixture("transactions/item-busy.derived.json", response.bodyAsText())
            }
        }

    @Test
    fun `parameters, the deprecated transaction key, a stranger and an unknown Échange`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val (owner: Reader, _, transactionId: String) = requested()
                val stranger: Reader = client.newReader()

                val unknownState: HttpResponse = client.updateState(owner, transactionId, "lost")
                val byStranger: HttpResponse = client.updateState(stranger, transactionId, "cancelled")
                val unknown: HttpResponse = client.updateState(owner, "0123456789abcdef0123456789abcdef", "accepted")
                val renamed: HttpResponse =
                    client.putJson(
                        owner,
                        "/api/transactions?action=update-state",
                        """{"state":"accepted","transaction":"$transactionId"}""",
                    )

                assertMatchesFixture("transactions/invalid-state.derived.json", unknownState.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, byStranger.status)
                assertEquals(HttpStatusCode.NotFound, unknown.status)
                assertEquals(HttpStatusCode.OK, renamed.status, renamed.bodyAsText())
            }
        }

    /** An owner, their friend, and the friend's request on the owner's lending book. */
    private suspend fun ApplicationTestBuilder.requested(): Triple<Reader, Reader, String> {
        val owner: Reader = client.newReader()
        val friend: Reader = client.newReader()
        client.befriend(owner, friend)
        return Triple(owner, friend, client.newTransaction(friend, client.newOfferedBook(owner)).id())
    }

    /** An Échange on a new book of [owner]'s offered as [mode], requested, accepted and confirmed; its id. */
    private suspend fun ApplicationTestBuilder.confirmed(
        owner: Reader,
        friend: Reader,
        mode: String,
    ): String {
        val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner, mode)).id()
        client.moveTo(owner, transactionId, "accepted")
        client.moveTo(friend, transactionId, "confirmed")
        return transactionId
    }

    private fun JsonObject.lastAction(): JsonObject = getValue("actions").jsonArray.last().jsonObject
}
