package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

class ListElementsRemovalRoutesTest {
    @Test
    fun `an element removed by uri answers the list alone, and by-creators no longer returns it`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                client.newElements(reader, listId, WORK_1984, SECOND_WORK)

                val response: HttpResponse =
                    client.listAction(reader, "remove-elements", """{"id":"$listId","uris":["$WORK_1984"]}""")

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("lists/remove-elements.derived.json", response.bodyAsText())
                assertMatchesShape(
                    fixture("lists/remove-elements.derived.json").getValue("list").jsonObject,
                    response.json().getValue("list").jsonObject,
                    "the list",
                )
                assertEquals(
                    listId,
                    response
                        .json()
                        .getValue("list")
                        .jsonObject
                        .id(),
                )
                assertEquals(
                    listOf(SECOND_WORK),
                    client
                        .listsOf(listOf(reader.id), reader)
                        .single()
                        .elements()
                        .map { it.getValue("uri").jsonPrimitive.content },
                )
            }
        }

    @Test
    fun `a uri the list does not hold answers 404, someone else's list 403`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val listId: String = client.newList(owner)
                client.newElements(owner, listId, WORK_1984)

                val absent: HttpResponse =
                    client.listAction(owner, "remove-elements", """{"id":"$listId","uris":["$ORWELL"]}""")
                val foreign: HttpResponse =
                    client.listAction(other, "remove-elements", """{"id":"$listId","uris":["$WORK_1984"]}""")

                assertEquals(HttpStatusCode.NotFound, absent.status)
                assertMatchesFixture("lists/remove-elements.not-found.derived.json", absent.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, foreign.status)
                assertMatchesFixture("lists/wrong-user.derived.json", foreign.bodyAsText())
            }
        }
}
