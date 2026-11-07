package studio.lunabee.exlibris.backend.search

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.putUser
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SearchRoutesTest {
    @Test
    fun `oliv finds OlivierB, in inventaire's shape, signed out`() =
        authTest {
            val olivier: Reader = client.newReader(username = "OlivierB")
            client.putUser(olivier, "picture", "\"/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877\"")
            val other: Reader = client.newReader(username = "Olgad_${olivier.id.take(6)}")

            val response: HttpResponse = client.getAs("/api/search?types=users&search=oliv&limit=10", null)

            assertEquals(HttpStatusCode.OK, response.status)
            assertMatchesFixture("search/users.json", response.bodyAsText())
            val results: JsonArray = response.json().getValue("results").jsonArray
            val first: JsonObject = results.first().jsonObject
            assertEquals(olivier.id, first.getValue("id").jsonPrimitive.content)
            assertEquals("OlivierB", first.getValue("label").jsonPrimitive.content)
            val expected: JsonArray = fixture("search/users.json").getValue("results").jsonArray
            assertMatchesShape(expected[0].jsonObject, first, "a reader with a picture")
            assertTrue(
                results.none {
                    it.jsonObject
                        .getValue("id")
                        .jsonPrimitive.content == other.id
                },
            )
        }

    @Test
    fun `a reader's bio is the hit's description`() =
        authTest {
            val reader: Reader = client.newReader()
            client.putUser(reader, "bio", "\"Lectrice\"")
            client.putUser(reader, "picture", "\"/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877\"")

            val hit: JsonObject =
                client
                    .getAs("/api/search?types=users&search=${reader.account.username}", null)
                    .json()
                    .getValue("results")
                    .jsonArray
                    .first()
                    .jsonObject

            val expected: JsonObject = fixture("search/users.bio.json").getValue("results").jsonArray[0].jsonObject
            assertMatchesShape(expected, hit, "a reader with a bio")
            assertEquals("Lectrice", hit.getValue("description").jsonPrimitive.content)
        }

    @Test
    fun `an underscore or a percent sign is a character, not a wildcard`() =
        authTest {
            client.newReader()

            // As wildcards, `e_d` would match "reader" and `%` everyone.
            listOf("e_d", "%25").forEach { term ->
                val results: JsonArray =
                    client
                        .getAs("/api/search?types=users&search=$term", null)
                        .json()
                        .getValue("results")
                        .jsonArray
                assertTrue(results.isEmpty(), "search=$term found $results")
            }
        }

    @Test
    fun `refusals keep inventaire's words`() =
        authTest {
            val mixed: HttpResponse = client.getAs("/api/search?types=users|works&search=oliv&limit=3", null)
            val missing: HttpResponse = client.getAs("/api/search?types=users", null)
            val unknown: HttpResponse = client.getAs("/api/search?types=foo&search=oliv", null)

            assertEquals(HttpStatusCode.BadRequest, mixed.status)
            assertMatchesFixture("search/mixed-types.json", mixed.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, missing.status)
            assertMatchesFixture("search/missing-search.json", missing.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, unknown.status)
            assertTrue(
                unknown
                    .json()
                    .getValue("message")
                    .jsonPrimitive.content
                    .startsWith("invalid types: foo"),
            )
        }

    @Test
    fun `the entity types are not served yet`() =
        authTest {
            assertEquals(HttpStatusCode.NotImplemented, client.getAs("/api/search?types=works&search=a", null).status)
        }
}
