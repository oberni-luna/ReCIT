package studio.lunabee.exlibris.backend.transactions

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.bookStub
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TransactionsListRoutesTest {
    @Test
    fun `both sides list the Échange, unread by the owner and read by the requester`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                val stranger: Reader = client.newReader()
                client.befriend(owner, friend)
                val transactionId: String = client.newTransaction(friend, client.newOfferedBook(owner)).id()

                val asOwner: List<JsonObject> = client.transactionsOf(owner)
                val asRequester: List<JsonObject> = client.transactionsOf(friend)

                assertEquals(listOf(transactionId), asOwner.map { it.id() })
                assertEquals(listOf(transactionId), asRequester.map { it.id() })
                assertFalse(asOwner.single().read("owner"))
                assertTrue(asOwner.single().read("requester"))
                assertEquals(emptyList(), client.transactionsOf(stranger))
            }
        }

    @Test
    fun `the list has inventaire's keys and types`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                client.newTransaction(friend, client.newOfferedBook(owner))

                val response: HttpResponse = client.getAs("/api/transactions", owner)

                assertEquals(HttpStatusCode.OK, response.status)
                assertMatchesFixture("transactions/transactions.derived.json", response.bodyAsText())
                assertTransactionShape(
                    "transactions/transactions.derived.json",
                    client.transactionsOf(owner).single(),
                ) { it.getValue("transactions").jsonArray[0].jsonObject }
            }
        }

    @Test
    fun `signed out, the list answers inventaire's 401 as captured`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val response: HttpResponse = client.getAs("/api/transactions", null)

                assertEquals(HttpStatusCode.Unauthorized, response.status)
                assertMatchesFixture("transactions/transactions.anonymous.json", response.bodyAsText())
            }
        }
}
