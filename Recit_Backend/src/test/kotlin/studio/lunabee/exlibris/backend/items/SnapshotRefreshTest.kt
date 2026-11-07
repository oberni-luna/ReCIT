package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.AppConfig
import studio.lunabee.exlibris.backend.AppContainer
import studio.lunabee.exlibris.backend.FixtureAssertions
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.TestPostgres
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.relayTest
import studio.lunabee.exlibris.backend.newReader
import kotlin.test.Test
import kotlin.test.assertEquals

/** The nightly job, run by hand: [AppContainer.snapshotsService]'s `refreshStale`, on the routes' database. */
class SnapshotRefreshTest {
    @Test
    fun `a snapshot read over 7 days ago gets inventaire's title again`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()
                ageSnapshot(EDITION_1984)
                stub.answer = { StubAnswer.json(retitled("Nineteen Eighty-Four")) }

                refreshStale(stub)

                assertEquals("Nineteen Eighty-Four", titleOf(client.visibleItems(listOf(itemId), owner).single()))
            }
        }

    @Test
    fun `a redirected edition moves its books to the new uri, which keeps the old one as previous`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val itemId: String = client.newBook(owner).id()
                AuthTestEnvironment.execute(
                    "INSERT INTO entity_snapshots (uri, title, works_uris, authors_uris, series_uris, refreshed) " +
                        "VALUES ('$MERGED', 'Ancienne fiche', '{}', '{}', '{}', 0) ON CONFLICT (uri) DO NOTHING",
                )
                AuthTestEnvironment.execute("UPDATE items SET entity = '$MERGED' WHERE id = '$itemId'")
                stub.answer = { request ->
                    if (MERGED in request.uri) StubAnswer.json(redirected()) else bookAnswer(request)
                }

                refreshStale(stub)

                val item: JsonObject = client.visibleItems(listOf(itemId), owner).single()
                assertEquals(EDITION_1984, item.getValue("entity").jsonPrimitive.content)
                assertEquals(listOf(MERGED), item.strings("previousEntities"))
                assertEquals("1984", titleOf(item))
            }
        }

    @Test
    fun `an edition inventaire no longer knows keeps its last snapshot, and a snapshot no book uses is dropped`() =
        bookStub().use { stub ->
            relayTest(stub) {
                val owner: Reader = client.newReader()
                val kept: String = client.newBook(owner).id()
                ageSnapshot(EDITION_1984)
                AuthTestEnvironment.execute(
                    "INSERT INTO entity_snapshots (uri, title, works_uris, authors_uris, series_uris, refreshed) " +
                        "VALUES ('$UNUSED', 'Sans livre', '{}', '{}', '{}', 0) ON CONFLICT (uri) DO NOTHING",
                )
                stub.answer = { StubAnswer.json(FixtureAssertions.read("entities/by-uris.not-found.json")) }

                refreshStale(stub)

                assertEquals("1984", titleOf(client.visibleItems(listOf(kept), owner).single()))
                assertEquals(0, count("SELECT count(*) FROM entity_snapshots WHERE uri = '$UNUSED'"))
                assertEquals(
                    0,
                    count("SELECT count(*) FROM entity_snapshots WHERE refreshed = 0 AND uri = '$EDITION_1984'"),
                )
            }
        }

    private suspend fun refreshStale(stub: InventaireStub) {
        val config = TestPostgres.config(AuthTestEnvironment.postgres, AuthTestEnvironment.mailpit, stub.baseUrl)
        AppContainer(AppConfig.from(config)).use { it.snapshotsService.refreshStale() }
    }

    private fun ageSnapshot(uri: String) {
        AuthTestEnvironment.execute("UPDATE entity_snapshots SET refreshed = 0 WHERE uri = '$uri'")
    }

    private fun titleOf(item: JsonObject): String =
        item
            .getValue("snapshot")
            .jsonObject
            .getValue("entity:title")
            .jsonPrimitive.content

    private fun count(query: String): Long = AuthTestEnvironment.queryLong(query)

    /** The captured answer, as inventaire.io answers an edition merged into « 1984 »'s. */
    private fun redirected(): String =
        FixtureAssertions
            .read("entities/by-uris.isbn-9782070368228.relatives.json")
            .replace(ISBN_1984, MERGED)

    private companion object {
        const val MERGED: String = "inv:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        const val UNUSED: String = "inv:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    }
}
