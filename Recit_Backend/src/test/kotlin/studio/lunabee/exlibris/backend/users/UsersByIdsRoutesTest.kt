package studio.lunabee.exlibris.backend.users

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesShape
import studio.lunabee.exlibris.backend.FixtureAssertions.fixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.postRelation
import studio.lunabee.exlibris.backend.putUser
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class UsersByIdsRoutesTest {
    private val fixtureUsers: JsonObject = fixture("users/by-ids.json").getValue("users").jsonObject

    @Test
    fun `two readers come back with their public fields, as inventaire shows them, never an address`() =
        authTest {
            val withPicture: Reader = client.newReader()
            val without: Reader = client.newReader()
            client.putUser(withPicture, "picture", "\"/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877\"")
            client.putUser(withPicture, "language", "\"de\"")

            val response: HttpResponse = client.getAs("/api/users/by-ids?ids=${withPicture.id}|${without.id}", null)

            assertEquals(HttpStatusCode.OK, response.status)
            val body: String = response.bodyAsText()
            val users: JsonObject = response.json().getValue("users").jsonObject
            assertEquals(setOf(withPicture.id, without.id), users.keys)
            assertMatchesShape(
                fixtureUsers.getValue("22cde913162063ef6f1ee45ebd051477").jsonObject,
                users.getValue(withPicture.id).jsonObject,
                "a reader with a picture",
            )
            assertMatchesShape(
                fixtureUsers.getValue("4519939c6c5fb623a53e04e57a4997d2").jsonObject,
                users.getValue(without.id).jsonObject,
                "a reader without one",
            )
            assertFalse(body.contains("@example.org"))
            assertFalse(body.contains("\"email\""))
            assertFalse(body.contains("\"language\""))
        }

    @Test
    fun `a position and a bio are public, a friend sees the network part of the snapshot`() =
        authTest {
            val reader: Reader = client.newReader()
            val friend: Reader = client.newReader()
            client.putUser(reader, "position", "[43.5813, 7.1262]")
            client.putUser(reader, "picture", "\"/img/users/bdc099e52a6b3cecd4368f52ef001ae534a5e54e\"")
            client.postRelation(friend, "request", reader)
            client.postRelation(reader, "accept", friend)

            val anonymous: JsonObject =
                client
                    .getAs("/api/users/by-ids?ids=${reader.id}", null)
                    .json()
                    .getValue("users")
                    .jsonObject
            val byFriend: JsonObject =
                client
                    .getAs("/api/users/by-ids?ids=${reader.id}", friend)
                    .json()
                    .getValue("users")
                    .jsonObject

            val expected: JsonObject =
                fixture("users/by-ids.position.json")
                    .getValue("users")
                    .jsonObject.values
                    .single()
                    .jsonObject
            assertMatchesShape(expected, anonymous.getValue(reader.id).jsonObject, "a reader with a position")
            assertEquals(
                setOf("public"),
                anonymous
                    .getValue(reader.id)
                    .jsonObject
                    .getValue("snapshot")
                    .jsonObject.keys,
            )
            assertEquals(
                setOf("network", "public"),
                byFriend
                    .getValue(reader.id)
                    .jsonObject
                    .getValue("snapshot")
                    .jsonObject.keys,
            )
        }

    @Test
    fun `the caller's own id comes back as their own document, an unknown id not at all`() =
        authTest {
            val reader: Reader = client.newReader()

            val users: JsonObject =
                client
                    .getAs("/api/users/by-ids?ids=${reader.id}|00000000000000000000000000000001", reader)
                    .json()
                    .getValue("users")
                    .jsonObject

            assertEquals(setOf(reader.id), users.keys)
            assertTrue(users.getValue(reader.id).jsonObject.containsKey("email"))
        }

    @Test
    fun `a missing or malformed id is refused as inventaire refuses it`() =
        authTest {
            val missing: HttpResponse = client.getAs("/api/users/by-ids", null)
            val invalid: HttpResponse = client.getAs("/api/users/by-ids?ids=notanid", null)

            assertEquals(HttpStatusCode.BadRequest, missing.status)
            assertMatchesFixture("users/by-ids.missing.json", missing.bodyAsText())
            assertEquals(HttpStatusCode.BadRequest, invalid.status)
            assertMatchesFixture("users/by-ids.invalid.json", invalid.bodyAsText())
        }
}
