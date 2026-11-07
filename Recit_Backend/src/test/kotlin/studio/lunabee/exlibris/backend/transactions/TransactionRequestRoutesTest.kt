package studio.lunabee.exlibris.backend.transactions

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.EDITION_1984
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.postJsonAnonymously
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class TransactionRequestRoutesTest {
    @Test
    fun `a friend asks for my lending book, requested, typed lending, with its message and a snapshot`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val itemId: String = client.newOfferedBook(owner, details = "Annoté")

                val response: HttpResponse = client.requestBook(friend, itemId)

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                val transaction: JsonObject = response.json().getValue("transaction").jsonObject
                assertEquals("requested", transaction.text("state"))
                assertEquals("lending", transaction.text("transaction"))
                assertEquals(itemId, transaction.text("item"))
                assertEquals(owner.id, transaction.text("owner"))
                assertEquals(friend.id, transaction.text("requester"))
                assertEquals(listOf("requested"), transaction.actions())
                val snapshot: JsonObject = transaction.getValue("snapshot").jsonObject
                assertEquals("1984", snapshot.getValue("entity").jsonObject.text("title"))
                assertEquals(EDITION_1984, snapshot.getValue("item").jsonObject.text("entity"))
                assertEquals("Annoté", snapshot.getValue("item").jsonObject.text("details"))
                assertEquals(owner.account.username, snapshot.getValue("owner").jsonObject.text("username"))
                assertEquals(friend.account.username, snapshot.getValue("requester").jsonObject.text("username"))
                val messages: List<JsonObject> = client.messagesOf(owner, transaction.id())
                assertEquals(listOf("Je peux ?"), messages.map { it.text("message") })
                assertEquals(friend.id, messages.single().text("user"))
            }
        }

    @Test
    fun `the answer has inventaire's keys and types`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)

                val response: HttpResponse = client.requestBook(friend, client.newOfferedBook(owner))

                assertMatchesFixture("transactions/request.derived.json", response.bodyAsText())
                assertTransactionShape(
                    "transactions/request.derived.json",
                    response.json().getValue("transaction").jsonObject,
                )
            }
        }

    @Test
    fun `iOS's legacy POST with the action in the body, and the action in the query, both request`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val first: String = client.newOfferedBook(owner, mode = "giving")
                val second: String = client.newOfferedBook(owner, mode = "selling")

                val inBody: HttpResponse =
                    client.postJson(
                        "/api/transactions",
                        """{"action":"request","item":"$first","message":"Je peux ?"}""",
                        friend.cookies,
                    )
                val inQuery: HttpResponse =
                    client.postJson(
                        "/api/transactions?action=request",
                        """{"item":"$second","message":"Et celui-ci ?"}""",
                        friend.cookies,
                    )

                assertEquals(HttpStatusCode.OK, inBody.status, inBody.bodyAsText())
                assertEquals(HttpStatusCode.OK, inQuery.status, inQuery.bodyAsText())
                assertEquals(
                    listOf("giving", "selling"),
                    client.transactionsOf(friend).map { it.text("transaction") },
                )
            }
        }

    @Test
    fun `an inventoried book, my own book, a book I may not see answer inventaire's error and create nothing`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val inventoried: String = client.newOfferedBook(owner, mode = "inventorying")
                val forFriends: String = client.newOfferedBook(owner)

                val notOffered: HttpResponse = client.requestBook(friend, inventoried)
                val mine: HttpResponse = client.requestBook(owner, forFriends)
                val unseen: HttpResponse = client.requestBook(stranger, forFriends)

                assertEquals(HttpStatusCode.BadRequest, notOffered.status)
                assertMatchesFixture("transactions/not-requestable.derived.json", notOffered.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, mine.status)
                assertMatchesFixture("transactions/not-allowed.derived.json", mine.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, unseen.status)
                assertMatchesFixture("transactions/not-allowed.derived.json", unseen.bodyAsText())
                assertEquals(0, countRows("SELECT count(*) FROM transactions WHERE owner = '${owner.id}'"))
            }
        }

    @Test
    fun `asking twice, or for a book an accepted Échange holds, is refused`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val other: Reader = client.newReader()
                client.befriend(owner, friend)
                client.befriend(owner, other)
                val itemId: String = client.newOfferedBook(owner)
                val transactionId: String = client.newTransaction(friend, itemId).id()

                val twice: HttpResponse = client.requestBook(friend, itemId)
                client.moveTo(owner, transactionId, "accepted")
                val busy: HttpResponse = client.requestBook(other, itemId)

                assertEquals(HttpStatusCode.Forbidden, twice.status)
                assertMatchesFixture("transactions/already-requested.derived.json", twice.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, busy.status)
                assertMatchesFixture("transactions/item-busy.derived.json", busy.bodyAsText())
                assertEquals(1, countRows("SELECT count(*) FROM transactions WHERE item = '$itemId'"))
            }
        }

    @Test
    fun `a finished Échange lets me ask again`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val itemId: String = client.newOfferedBook(owner)
                client.moveTo(owner, client.newTransaction(friend, itemId).id(), "declined")

                assertEquals(HttpStatusCode.OK, client.requestBook(friend, itemId).status)
            }
        }

    @Test
    fun `parameters are checked as inventaire's sanitizer checks them`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()

                val noItem: HttpResponse =
                    client.postJson(
                        "/api/transactions/request",
                        """{"message":"x"}""",
                        reader.cookies,
                    )
                val badItem: HttpResponse = client.requestBook(reader, "nope")
                val emptyMessage: HttpResponse = client.requestBook(reader, "0123456789abcdef0123456789abcdef", " ")
                val unknown: HttpResponse = client.requestBook(reader, "0123456789abcdef0123456789abcdef")
                val anonymous: HttpResponse =
                    client.postJsonAnonymously("/api/transactions/request", """{"item":"x","message":"x"}""")

                assertMatchesFixture("transactions/request.missing-item.derived.json", noItem.bodyAsText())
                assertEquals("invalid item: nope", badItem.json().text("message"))
                assertEquals(HttpStatusCode.BadRequest, emptyMessage.status)
                assertMatchesFixture("transactions/empty-message.derived.json", emptyMessage.bodyAsText())
                assertEquals(HttpStatusCode.NotFound, unknown.status)
                assertMatchesFixture("groups/by-id.not-found.json", unknown.bodyAsText())
                assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
            }
        }
}
