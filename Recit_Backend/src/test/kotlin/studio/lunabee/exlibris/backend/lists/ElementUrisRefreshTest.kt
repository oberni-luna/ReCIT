package studio.lunabee.exlibris.backend.lists

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.AppConfig
import studio.lunabee.exlibris.backend.AppContainer
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.items.WORK_1984
import studio.lunabee.exlibris.backend.items.id
import studio.lunabee.exlibris.backend.items.strings
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

/** The nightly job's lists half, run by hand: [AppContainer.elementUrisService]'s `refreshStale`. */
class ElementUrisRefreshTest {
    @Test
    fun `an element whose uri inventaire now redirects is moved to the target, the old uri kept as previous`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val elementId: String = client.newElements(reader, listId, WORK_1984).single().id()
                AuthTestEnvironment.execute(
                    "UPDATE list_elements SET uri = '$REDIRECTED', uri_checked = 0 WHERE id = '$elementId'",
                )

                refreshStale(stub)

                val element: JsonObject =
                    client
                        .listsOf(listOf(reader.id), reader)
                        .single()
                        .elements()
                        .single()
                assertEquals(elementId, element.id())
                assertEquals(REDIRECT_TARGET, element.getValue("uri").jsonPrimitive.content)
                assertEquals(listOf(REDIRECTED), element.strings("previousUris"))
            }
        }

    @Test
    fun `in a list already holding the target, one element remains, carrying the redirected one's comment`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val redirected: String = client.newElements(reader, listId, WORK_1984).single().id()
                val target: String = client.newElements(reader, listId, REDIRECT_TARGET).single().id()
                client.listAction(reader, "update-element", """{"id":"$redirected","comment":"Relu en 2024"}""")
                AuthTestEnvironment.execute(
                    "UPDATE list_elements SET uri = '$REDIRECTED', uri_checked = 0 WHERE id = '$redirected'",
                )

                refreshStale(stub)

                val element: JsonObject =
                    client
                        .listsOf(listOf(reader.id), reader)
                        .single()
                        .elements()
                        .single()
                assertEquals(target, element.id())
                assertEquals(REDIRECT_TARGET, element.getValue("uri").jsonPrimitive.content)
                assertEquals("Relu en 2024", element.getValue("comment").jsonPrimitive.content)
            }
        }

    @Test
    fun `a uri checked this week is not asked again, one inventaire no longer knows is kept`() =
        listStub().use { stub ->
            relayTest(stub) {
                val reader: Reader = client.newReader()
                val listId: String = client.newList(reader)
                val fresh: String = client.newElements(reader, listId, WORK_1984).single().id()
                val lost: String = client.newElements(reader, listId, SECOND_WORK).single().id()
                AuthTestEnvironment.execute(
                    "UPDATE list_elements SET uri = '$UNKNOWN_WORK', uri_checked = 0 WHERE id = '$lost'",
                )
                val before: Int = stub.requests.size

                refreshStale(stub)

                val asked: List<String> = stub.requests.drop(before).map { it.uri }
                assertEquals(1, asked.size)
                assertEquals(false, asked.single().contains(WORK_1984))
                val uris: Map<String, String> =
                    client.listsOf(listOf(reader.id), reader).single().elements().associate {
                        it.id() to it.getValue("uri").jsonPrimitive.content
                    }
                assertEquals(mapOf(fresh to WORK_1984, lost to UNKNOWN_WORK), uris)
            }
        }

    private suspend fun refreshStale(stub: InventaireStub) {
        val config = TestPostgres.config(AuthTestEnvironment.postgres, AuthTestEnvironment.mailpit, stub.baseUrl)
        AppContainer(AppConfig.from(config)).use { it.elementUrisService.refreshStale() }
    }
}
