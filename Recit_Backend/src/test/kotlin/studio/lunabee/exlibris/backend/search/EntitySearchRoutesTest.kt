package studio.lunabee.exlibris.backend.search

import io.ktor.client.request.get
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.entities.InventaireStub
import studio.lunabee.exlibris.backend.entities.StubAnswer
import studio.lunabee.exlibris.backend.entities.relayTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EntitySearchRoutesTest {
    @Test
    fun `entity types alone are searched by inventaire, the query as sent`() =
        InventaireStub().use { stub ->
            val results = """{"results":[{"id":"Q190192","uri":"wd:Q190192","label":"Dune","_score":1}]}"""
            stub.answer = { StubAnswer.json(results) }
            relayTest(stub) {
                // `%7C`: the stub's JDK server refuses a raw `|`, which inventaire.io takes as well.
                val path = "/api/search?types=works%7Chumans&search=dune&lang=fr&limit=10"

                val response: HttpResponse = client.get(path)

                assertEquals(HttpStatusCode.OK, response.status)
                assertEquals(results, response.bodyAsText())
                assertEquals(listOf(path), stub.requests.map { it.uri })
            }
        }

    @Test
    fun `social and entity types mixed are refused here, without asking inventaire`() =
        InventaireStub().use { stub ->
            relayTest(stub) {
                val response: HttpResponse = client.get("/api/search?types=users|works&search=dune")

                assertEquals(HttpStatusCode.BadRequest, response.status)
                assertMatchesFixture("search/mixed-types.json", response.bodyAsText())
                assertTrue(stub.requests.isEmpty())
            }
        }
}
