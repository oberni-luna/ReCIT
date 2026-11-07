package studio.lunabee.exlibris.backend.lists

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.befriend
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ListElementUpdateRoutesTest {
    @Test
    fun `a comment written answers the element carrying it, an empty one clears it`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val elementId: String = client.newElements(reader, listId, WORK_1984).single().id()

                val commented: HttpResponse =
                    client.listAction(reader, "update-element", """{"id":"$elementId","comment":"x"}""")
                val cleared: HttpResponse =
                    client.listAction(reader, "update-element", """{"id":"$elementId","comment":""}""")

                assertEquals(HttpStatusCode.OK, commented.status, commented.bodyAsText())
                assertMatchesFixture("lists/update-element.derived.json", commented.bodyAsText())
                assertEquals("x", commented.json().text("comment"))
                assertTrue(commented.json().text("_rev").startsWith("2-"))
                assertEquals("", cleared.json().text("comment"))
                assertEquals(
                    "",
                    client
                        .listsOf(listOf(reader.id), reader)
                        .single()
                        .elements()
                        .single()
                        .text("comment"),
                )
            }
        }

    @Test
    fun `the same comment again is nothing to update, and a friend's comment on my list is refused`() =
        listStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val friend: Reader = client.newReader()
                client.befriend(owner, friend)
                val listId: String = client.newList(owner, visibility = """["friends"]""")
                val elementId: String = client.newElements(owner, listId, WORK_1984).single().id()
                client.listAction(owner, "update-element", """{"id":"$elementId","comment":"x"}""")

                val again: HttpResponse =
                    client.listAction(
                        owner,
                        "update-element",
                        """{"id":"$elementId","comment":"x"}""",
                    )
                val foreign: HttpResponse =
                    client.listAction(friend, "update-element", """{"id":"$elementId","comment":"à moi"}""")

                assertEquals(HttpStatusCode.BadRequest, again.status)
                assertMatchesFixture("lists/update.nothing-to-update.derived.json", again.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, foreign.status)
                assertMatchesFixture("lists/wrong-user.derived.json", foreign.bodyAsText())
            }
        }

    @Test
    fun `list moves the element to the end of another list, never into one already holding it`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val source: String = client.newList(reader, "Source")
                val recipient: String = client.newList(reader, "Destination")
                val authors: String = client.newList(reader, "Autrices", type = "author")
                val moving: String = client.newElements(reader, source, WORK_1984).single().id()
                client.newElements(reader, recipient, SECOND_WORK)
                val staying: String = client.newElements(reader, source, SECOND_WORK).single().id()

                val moved: HttpResponse =
                    client.listAction(reader, "update-element", """{"id":"$moving","list":"$recipient"}""")
                val held: HttpResponse =
                    client.listAction(reader, "update-element", """{"id":"$staying","list":"$recipient"}""")
                val wrongType: HttpResponse =
                    client.listAction(reader, "update-element", """{"id":"$staying","list":"$authors"}""")

                assertEquals(HttpStatusCode.OK, moved.status, moved.bodyAsText())
                assertEquals(recipient, moved.json().text("list"))
                assertEquals("111", moved.json().text("ordinal"))
                assertEquals(HttpStatusCode.BadRequest, held.status)
                assertMatchesFixture("lists/update-element.already-in-list.derived.json", held.bodyAsText())
                assertEquals(HttpStatusCode.Forbidden, wrongType.status)
                assertMatchesFixture("lists/add-elements.wrong-type.derived.json", wrongType.bodyAsText())
            }
        }

    private fun JsonObject.text(key: String): String = getValue(key).jsonPrimitive.content
}
