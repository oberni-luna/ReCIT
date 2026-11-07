package studio.lunabee.exlibris.backend.relations

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.postRelation
import kotlin.test.Test
import kotlin.test.assertEquals

class RelationsRoutesTest {
    @Test
    fun `a request lands in the other's otherRequested, and accepting it makes both friends`() =
        authTest {
            val a: Reader = client.newReader()
            val b: Reader = client.newReader()

            val request: HttpResponse = client.postRelation(a, "request", b)

            assertEquals(HttpStatusCode.OK, request.status)
            assertMatchesFixture("auth/ok.derived.json", request.bodyAsText())
            assertRelations(a, userRequested = listOf(b.id))
            assertRelations(b, otherRequested = listOf(a.id))

            client.postRelation(b, "accept", a)

            assertRelations(a, friends = listOf(b.id))
            assertRelations(b, friends = listOf(a.id))
        }

    @Test
    fun `unfriending leaves neither in the other's lists`() =
        authTest {
            val (a: Reader, b: Reader) = friends()

            client.postRelation(a, "unfriend", b)

            assertRelations(a)
            assertRelations(b)
        }

    @Test
    fun `a request cancelled leaves nothing`() =
        authTest {
            val a: Reader = client.newReader()
            val b: Reader = client.newReader()
            client.postRelation(a, "request", b)

            client.postRelation(a, "cancel", b)

            assertRelations(a)
            assertRelations(b)
        }

    @Test
    fun `a request discarded leaves nothing`() =
        authTest {
            val a: Reader = client.newReader()
            val b: Reader = client.newReader()
            client.postRelation(a, "request", b)

            client.postRelation(b, "discard", a)

            assertRelations(a)
            assertRelations(b)
        }

    @Test
    fun `asking someone who already asked makes both friends`() =
        authTest {
            val a: Reader = client.newReader()
            val b: Reader = client.newReader()
            client.postRelation(b, "request", a)

            client.postRelation(a, "request", b)

            assertRelations(a, friends = listOf(b.id))
            assertRelations(b, friends = listOf(a.id))
        }

    @Test
    fun `an action that does not fit changes nothing and still answers ok`() =
        authTest {
            val a: Reader = client.newReader()
            val b: Reader = client.newReader()

            val accept: HttpResponse = client.postRelation(a, "accept", b)
            client.postRelation(a, "request", b)
            client.postRelation(a, "request", b)
            client.postRelation(a, "accept", b)

            assertEquals(HttpStatusCode.OK, accept.status)
            assertRelations(a, userRequested = listOf(b.id))
            assertRelations(b, otherRequested = listOf(a.id))
        }

    @Test
    fun `the four lists come in inventaire's shape`() =
        authTest {
            val (me: Reader, friend: Reader) = friends()
            val asked: Reader = client.newReader()
            client.postRelation(me, "request", asked)

            val response: HttpResponse = client.getAs("/api/relations", me)

            assertMatchesFixture("relations/relations.derived.json", response.bodyAsText())
            assertEquals(listOf(friend.id), response.json().ids("network"))
        }

    @Test
    fun `refusals keep inventaire's words`() =
        authTest {
            val a: Reader = client.newReader()

            val anonymous: HttpResponse = client.getAs("/api/relations", null)
            val identical: HttpResponse = client.postRelation(a, "request", a)
            val unknown: HttpResponse =
                client.postJson("/api/relations/request", """{"user":"00000000000000000000000000000001"}""", a.cookies)
            val malformed: HttpResponse = client.postJson("/api/relations/request", """{"user":"nope"}""", a.cookies)
            val missing: HttpResponse = client.postJson("/api/relations/request", "{}", a.cookies)

            assertEquals(HttpStatusCode.Unauthorized, anonymous.status)
            assertMatchesFixture("relations/relations.anonymous.json", anonymous.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, identical.status)
            assertMatchesFixture("relations/identical-ids.derived.json", identical.bodyAsText())
            assertEquals(HttpStatusCode.NotFound, unknown.status)
            assertMatchesFixture("relations/request.unknown-user.derived.json", unknown.bodyAsText())
            assertEquals(
                "invalid_user",
                malformed
                    .json()
                    .getValue("error_name")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "missing_user",
                missing
                    .json()
                    .getValue("error_name")
                    .jsonPrimitive.content,
            )
        }

    private suspend fun ApplicationTestBuilder.friends(): Pair<Reader, Reader> {
        val a: Reader = client.newReader()
        val b: Reader = client.newReader()
        client.postRelation(a, "request", b)
        client.postRelation(b, "accept", a)
        return a to b
    }

    private suspend fun ApplicationTestBuilder.assertRelations(
        reader: Reader,
        friends: List<String> = emptyList(),
        userRequested: List<String> = emptyList(),
        otherRequested: List<String> = emptyList(),
    ) {
        val relations: JsonObject = client.getAs("/api/relations", reader).json()
        assertEquals(friends, relations.ids("friends"), "friends of ${reader.id}")
        assertEquals(userRequested, relations.ids("userRequested"), "userRequested of ${reader.id}")
        assertEquals(otherRequested, relations.ids("otherRequested"), "otherRequested of ${reader.id}")
        assertEquals(friends, relations.ids("network"), "network of ${reader.id}")
    }

    private fun JsonObject.ids(list: String): List<String> = getValue(list).jsonArray.map { it.jsonPrimitive.content }
}
