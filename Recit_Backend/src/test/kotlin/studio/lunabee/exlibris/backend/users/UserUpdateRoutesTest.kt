package studio.lunabee.exlibris.backend.users

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.Reader
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.getAs
import studio.lunabee.exlibris.backend.json
import studio.lunabee.exlibris.backend.newReader
import studio.lunabee.exlibris.backend.putUser
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class UserUpdateRoutesTest {
    @Test
    fun `bio, language, position and picture come back from GET user, in inventaire's shape`() =
        authTest {
            val reader: Reader = client.newReader()
            val picture = "/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877"

            listOf(
                "bio" to "\"Lectrice de romans noirs\"",
                "language" to "\"de\"",
                "position" to "[48.8566, 2.3522]",
                "picture" to "\"$picture\"",
                "fediversable" to "true",
                "summaryPeriodicity" to "10",
                "settings.notifications.global" to "false",
                "settings.contributions.anonymize" to "false",
            ).forEach { (attribute, value) ->
                val response: HttpResponse = client.putUser(reader, attribute, value)
                assertEquals(HttpStatusCode.OK, response.status, "$attribute: ${response.bodyAsText()}")
                assertMatchesFixture("auth/ok.derived.json", response.bodyAsText())
            }

            val user: JsonObject = client.getAs("/api/user", reader).json()
            assertMatchesFixture("user/user.owner.profile.derived.json", user.toString())
            assertEquals("Lectrice de romans noirs", user.getValue("bio").jsonPrimitive.content)
            assertEquals("de", user.getValue("language").jsonPrimitive.content)
            assertEquals(listOf(48.8566, 2.3522), user.getValue("position").jsonArray.map { it.jsonPrimitive.double })
            assertEquals(picture, user.getValue("picture").jsonPrimitive.content)
            assertTrue(user.getValue("fediversable").jsonPrimitive.boolean)
            assertEquals(10, user.getValue("summaryPeriodicity").jsonPrimitive.int)
            val settings: JsonObject = user.getValue("settings").jsonObject
            assertFalse(
                settings
                    .getValue("notifications")
                    .jsonObject
                    .getValue("global")
                    .jsonPrimitive.boolean,
            )
            assertFalse(
                settings
                    .getValue("contributions")
                    .jsonObject
                    .getValue("anonymize")
                    .jsonPrimitive.boolean,
            )
            assertEquals(
                "9",
                user
                    .getValue("_rev")
                    .jsonPrimitive.content
                    .substringBefore('-'),
            )
        }

    @Test
    fun `a position keeps five decimals, and null takes the position and the picture away`() =
        authTest {
            val reader: Reader = client.newReader()
            client.putUser(reader, "position", "[45.1234567, -0.000006]")
            client.putUser(reader, "picture", "\"/img/users/3af17a8d008b00047d93b00b3f77fbe00df75877\"")

            val placed: JsonArray =
                client
                    .getAs("/api/user", reader)
                    .json()
                    .getValue("position")
                    .jsonArray
            assertEquals(listOf(45.12346, -0.00001), placed.map { it.jsonPrimitive.double })

            assertEquals(HttpStatusCode.OK, client.putUser(reader, "position", "null").status)
            assertEquals(HttpStatusCode.OK, client.putUser(reader, "picture", "null").status)
            val user: JsonObject = client.getAs("/api/user", reader).json()
            assertNull(user["position"])
            assertNull(user["picture"])
        }

    @Test
    fun `a username taken is refused with inventaire's words, a free one renames`() =
        authTest {
            val first: Reader = client.newReader()
            val second: Reader = client.newReader()

            val taken: HttpResponse = client.putUser(second, "username", "\"${first.account.username.uppercase()}\"")
            assertEquals(HttpStatusCode.BadRequest, taken.status)
            assertMatchesFixture("user/update.username-taken.derived.json", taken.bodyAsText())

            val newName = "renamed_${second.id.take(8)}"
            assertEquals(HttpStatusCode.OK, client.putUser(second, "username", "\"$newName\"").status)
            assertEquals(
                newName,
                client
                    .getAs("/api/user", second)
                    .json()
                    .getValue("username")
                    .jsonPrimitive.content,
            )

            val reserved: HttpResponse = client.putUser(second, "username", "\"profile\"")
            assertEquals(HttpStatusCode.BadRequest, reserved.status)
            assertMatchesFixture("auth/username-availability.reserved.json", reserved.bodyAsText())
        }

    @Test
    fun `changing only the case of one's username needs no check`() =
        authTest {
            val reader: Reader = client.newReader()
            val upper: String = reader.account.username.uppercase()

            assertEquals(HttpStatusCode.OK, client.putUser(reader, "username", "\"$upper\"").status)
            assertEquals(
                upper,
                client
                    .getAs("/api/user", reader)
                    .json()
                    .getValue("username")
                    .jsonPrimitive.content,
            )
        }

    @Test
    fun `a new address shows unconfirmed and its confirmation link is mailed to it`() =
        authTest {
            val reader: Reader = client.newReader()
            val confirmed: String = AuthTestEnvironment.mailedLink(reader.account.email, "/confirm-email")
            client.getAs(confirmed, null)
            assertTrue(
                client
                    .getAs("/api/user", reader)
                    .json()
                    .getValue("validEmail")
                    .jsonPrimitive.boolean,
            )

            val address = "moved-${reader.id.take(12)}@example.org"
            assertEquals(HttpStatusCode.OK, client.putUser(reader, "email", "\"$address\"").status)

            val user: JsonObject = client.getAs("/api/user", reader).json()
            assertEquals(address, user.getValue("email").jsonPrimitive.content)
            assertFalse(user.getValue("validEmail").jsonPrimitive.boolean)
            val link: String = AuthTestEnvironment.mailedLink(address, "/confirm-email")
            client.getAs(link, null)
            assertTrue(
                client
                    .getAs("/api/user", reader)
                    .json()
                    .getValue("validEmail")
                    .jsonPrimitive.boolean,
            )
        }

    @Test
    fun `an address another account holds is refused`() =
        authTest {
            val first: Reader = client.newReader()
            val second: Reader = client.newReader()

            val response: HttpResponse = client.putUser(second, "email", "\"${first.account.email}\"")

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/signup.email-taken.derived.json", response.bodyAsText())
        }

    @Test
    fun `refusals keep inventaire's words`() =
        authTest {
            val reader: Reader = client.newReader()
            client.putUser(reader, "bio", "\"Lectrice\"")

            val cases: List<Triple<String, String, Pair<HttpStatusCode, String>>> =
                listOf(
                    Triple("bio", "\"Lectrice\"", HttpStatusCode.BadRequest to "user/update.up-to-date.derived.json"),
                    Triple("password", "\"x\"", HttpStatusCode.Forbidden to "user/update.forbidden.derived.json"),
                    Triple("bio", "null", HttpStatusCode.BadRequest to "user/update.missing-value.derived.json"),
                    Triple(
                        "language",
                        "\"xx_YY_zz_1\"",
                        HttpStatusCode.BadRequest to "user/update.invalid-value.derived.json",
                    ),
                )
            cases.forEach { (attribute, value, expected) ->
                val response: HttpResponse = client.putUser(reader, attribute, value)
                assertEquals(expected.first, response.status, "$attribute $value")
                assertMatchesFixture(expected.second, response.bodyAsText())
            }
        }

    @Test
    fun `a bio past a thousand characters, an unknown setting and a non-boolean switch are refused`() =
        authTest {
            val reader: Reader = client.newReader()

            val long: HttpResponse = client.putUser(reader, "bio", JsonPrimitive("a".repeat(1001)).toString())
            val unknown: HttpResponse = client.putUser(reader, "settings.notifications.everything", "true")
            val notBoolean: HttpResponse = client.putUser(reader, "fediversable", "\"yes\"")

            assertEquals(HttpStatusCode.BadRequest, long.status)
            assertEquals(
                "invalid_value",
                long
                    .json()
                    .getValue("error_name")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "invalid_attribute",
                unknown
                    .json()
                    .getValue("error_name")
                    .jsonPrimitive.content,
            )
            assertEquals(
                "invalid value: yes",
                notBoolean
                    .json()
                    .getValue("message")
                    .jsonPrimitive.content,
            )
            assertEquals(
                HttpStatusCode.OK,
                client.putUser(reader, "bio", JsonPrimitive("a".repeat(1000)).toString()).status,
            )
        }

    @Test
    fun `signed out, an update is refused`() =
        authTest {
            val reader: Reader = client.newReader()

            val response: HttpResponse = client.putUser(reader.copy(cookies = emptyMap()), "bio", "\"x\"")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("user/user.anonymous.json", response.bodyAsText())
        }
}
