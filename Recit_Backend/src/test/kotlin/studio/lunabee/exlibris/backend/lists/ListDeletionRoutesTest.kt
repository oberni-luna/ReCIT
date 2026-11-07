package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.postJson
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ListDeletionRoutesTest {
    @Test
    fun `a list deleted, sent as the apps send its id alone, goes with its elements, both echoed`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val elementId: String = client.newElements(reader, listId, WORK_1984).single().id()

                val response: HttpResponse =
                    client.postJson(
                        "/api/lists/delete",
                        """{"ids":"$listId"}""",
                        reader.cookies,
                    )

                assertEquals(HttpStatusCode.OK, response.status, response.bodyAsText())
                assertMatchesFixture("lists/delete.derived.json", response.bodyAsText())
                val answer: JsonObject = response.json()
                assertMatchesShape(
                    fixture("lists/delete.derived.json").objects("elements").single(),
                    answer.objects("elements").single(),
                    "the element deleted",
                )
                assertEquals(listId, answer.objects("lists").single().id())
                assertEquals(elementId, answer.objects("elements").single().id())
                assertTrue(client.listsOf(listOf(reader.id), reader).isEmpty())
                assertEquals(
                    0,
                    AuthTestEnvironment.queryLong("SELECT count(*) FROM list_elements WHERE id = '$elementId'"),
                )
            }
        }

    @Test
    fun `someone else's list is refused to delete, and stays`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val other: Reader = client.newReader()
                val listId: String = client.newList(owner)

                val response: HttpResponse =
                    client.postJson("/api/lists?action=delete", """{"ids":["$listId"]}""", other.cookies)

                assertEquals(HttpStatusCode.Forbidden, response.status)
                assertMatchesFixture("lists/wrong-user.derived.json", response.bodyAsText())
                assertEquals(1, client.listsOf(listOf(owner.id), owner).size)
            }
        }
}
