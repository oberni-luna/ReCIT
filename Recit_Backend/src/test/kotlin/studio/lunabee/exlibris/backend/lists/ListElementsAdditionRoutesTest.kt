package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.exLibrisUserAgent
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ListElementsAdditionRoutesTest {
    @Test
    fun `a work added answers inventaire's createdElements, checked anonymously on inventaire`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)

                val response: HttpResponse = client.addElements(reader, listId, WORK_1984)

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("lists/add-elements.derived.json", response.bodyAsText())
                val element: JsonObject = response.json().objects("createdElements").single()
                assertMatchesShape(
                    fixture("lists/add-elements.derived.json").objects("createdElements").single(),
                    element,
                    "the element",
                )
                assertEquals(WORK_1984, element.text("uri"))
                assertEquals(listId, element.text("list"))
                assertEquals("11", element.text("ordinal"))
                assertTrue(Regex("^[0-9a-f]{32}$").matches(element.id()))
                val check = stub.requests.single()
                assertTrue(check.uri.startsWith("/api/entities/by-uris?uris=$WORK_1984"), check.uri)
                assertNull(check.header("Cookie"))
                assertTrue(exLibrisUserAgent.matches(check.header("User-Agent").orEmpty()))
            }
        }

    @Test
    fun `an author in a list of works is refused with inventaire's type error, and nothing is created`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)

                val response: HttpResponse = client.addElements(reader, listId, WORK_1984, ORWELL)
                val unknown: HttpResponse = client.addElements(reader, listId, UNKNOWN_WORK)

                assertEquals(HttpStatusCode.Forbidden, response.status)
                assertMatchesFixture("lists/add-elements.wrong-type.derived.json", response.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, unknown.status)
                assertMatchesFixture("lists/add-elements.not-found.derived.json", unknown.bodyAsText())
                assertEquals(emptyList(), client.listsOf(listOf(reader.id), reader).single().elements())
            }
        }

    @Test
    fun `the same work twice creates nothing the second time and comes back in alreadyInList`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val first: JsonObject = client.newElements(reader, listId, WORK_1984).single()

                val again: HttpResponse = client.addElements(reader, listId, WORK_1984)

                assertEquals(HttpStatusCode.OK, again.status, again.bodyAsText())
                assertMatchesFixture("lists/add-elements.already-in-list.derived.json", again.bodyAsText())
                assertEquals(emptyList(), again.json().objects("createdElements"))
                assertEquals(
                    first.id(),
                    again
                        .json()
                        .objects("alreadyInList")
                        .single()
                        .id(),
                )
                assertEquals(
                    1,
                    client
                        .listsOf(listOf(reader.id), reader)
                        .single()
                        .elements()
                        .size,
                )
            }
        }

    @Test
    fun `a uri inventaire redirects is stored as its target, and the next element comes after the last`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                client.newElements(reader, listId, WORK_1984)

                val created: List<JsonObject> = client.newElements(reader, listId, REDIRECTED, SECOND_WORK)
                val viaTarget: HttpResponse = client.addElements(reader, listId, REDIRECT_TARGET)

                assertEquals(listOf(REDIRECT_TARGET, SECOND_WORK), created.map { it.text("uri") })
                assertEquals(listOf("111", "1111"), created.map { it.text("ordinal") })
                assertEquals(
                    created.first().id(),
                    viaTarget
                        .json()
                        .objects("alreadyInList")
                        .single()
                        .id(),
                )
            }
        }

    @Test
    fun `the legacy forms add too, someone else's list is refused, inventaire failing answers 502`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val listId: String = client.newList(owner)

                val legacy: HttpResponse =
                    client.postJson(
                        "/api/lists?action=add-elements",
                        """{"id":"$listId","uris":"$WORK_1984"}""",
                        owner.cookies,
                    )
                val foreign: HttpResponse = client.addElements(other, listId, SECOND_WORK)
                stub.answer = { StubAnswer.json("""{"status":503}""", status = 503) }
                val down: HttpResponse = client.addElements(owner, listId, SECOND_WORK)

                assertEquals(HttpStatusCode.OK, legacy.status, legacy.bodyAsText())
                assertEquals(1, legacy.json().objects("createdElements").size)
                assertEquals(HttpStatusCode.Forbidden, foreign.status)
                assertMatchesFixture("lists/wrong-user.derived.json", foreign.bodyAsText())
                assertEquals(HttpStatusCode.BadGateway, down.status)
                assertEquals(
                    1,
                    client
                        .listsOf(listOf(owner.id), owner)
                        .single()
                        .elements()
                        .size,
                )
            }
        }

    private fun JsonObject.text(key: String): String = getValue(key).jsonPrimitive.content
}
