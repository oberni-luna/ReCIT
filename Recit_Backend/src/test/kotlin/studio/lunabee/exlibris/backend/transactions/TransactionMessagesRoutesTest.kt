package studio.lunabee.exlibris.backend.transactions

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TransactionMessagesRoutesTest {
    @Test
    fun `a message is added after the request's, and leaves the other side unread`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()

                val response: HttpResponse = client.postMessage(owner, transactionId, "Oui, passe samedi")

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("transactions/post-message.derived.json", response.bodyAsText())
                val messages: List<JsonObject> = client.messagesOf(friend, transactionId)
                assertEquals(listOf("Je peux ?", "Oui, passe samedi"), messages.map { it.text("message") })
                assertEquals(listOf(friend.id, owner.id), messages.map { it.text("user") })
                assertEquals(response.json().text("id"), messages.last().id())
                val transaction: JsonObject = client.transactionsOf(friend).single()
                assertFalse(transaction.read("requester"))
                assertTrue(transaction.read("owner"))
                assertTrue(transaction.text("_rev").startsWith("2-"))
            }
        }

    @Test
    fun `the messages have inventaire's keys and types`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()

                val response: HttpResponse = client.getAs("/api/transactions/messages?id=$transactionId", owner)

                assertMatchesFixture("transactions/messages.derived.json", response.bodyAsText())
                assertMatchesShape(
                    fixture("transactions/messages.derived.json").getValue("messages").jsonArray[0].jsonObject,
                    response
                        .json()
                        .getValue("messages")
                        .jsonArray[0]
                        .jsonObject,
                    "a message",
                )
            }
        }

    @Test
    fun `the legacy names and the deprecated transaction key read and write the same messages`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()

                val posted: HttpResponse =
                    client.postJson(
                        "/api/transactions?action=message",
                        """{"message":"Merci","transaction":"$transactionId"}""",
                        friend.cookies,
                    )
                val read: HttpResponse =
                    client.getAs("/api/transactions?action=get-messages&transaction=$transactionId", owner)

                assertEquals(HttpStatusCode.OK, posted.status, posted.bodyAsText())
                assertEquals(
                    2,
                    read
                        .json()
                        .getValue("messages")
                        .jsonArray.size,
                )
            }
        }

    @Test
    fun `a stranger neither reads nor writes, an empty message and an unknown Échange are refused`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()

                val strangerReads: HttpResponse = client.getAs("/api/transactions/messages?id=$transactionId", stranger)
                val strangerWrites: HttpResponse = client.postMessage(stranger, transactionId, "Moi aussi")
                val empty: HttpResponse = client.postMessage(owner, transactionId, "")
                val unknown: HttpResponse = client.postMessage(owner, "0123456789abcdef0123456789abcdef", "x")
                val noId: HttpResponse = client.getAs("/api/transactions/messages", owner)

                assertEquals(HttpStatusCode.Forbidden, strangerReads.status)
                assertMatchesFixture("transactions/wrong-user.derived.json", strangerWrites.bodyAsText())
                assertMatchesFixture("transactions/empty-message.derived.json", empty.bodyAsText())
                assertEquals(HttpStatusCode.NotFound, unknown.status)
                assertEquals("missing parameter in query: id", noId.json().text("message"))
                assertEquals(1, client.messagesOf(owner, transactionId).size)
            }
        }
}
