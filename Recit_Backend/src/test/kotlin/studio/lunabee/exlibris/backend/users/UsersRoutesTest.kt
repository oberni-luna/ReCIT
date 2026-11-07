package studio.lunabee.exlibris.backend.users

import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import studio.lunabee.exlibris.backend.auth.AuthTestEnvironment
import studio.lunabee.exlibris.backend.auth.TestAccount
import studio.lunabee.exlibris.backend.auth.authTest
import studio.lunabee.exlibris.backend.auth.sendCookies
import studio.lunabee.exlibris.backend.auth.sessionUser
import studio.lunabee.exlibris.backend.auth.setCookies
import studio.lunabee.exlibris.backend.auth.signup
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class UsersRoutesTest {
    @Test
    fun `an anonymous call is refused as inventaire refuses it`() =
        authTest {
            val response = client.get("/api/user")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
            assertMatchesFixture("user/user.anonymous.json", response.bodyAsText())
        }

    @Test
    fun `the signed-in user reads their own document, in inventaire's shape`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val cookies: Map<String, String> = client.signup(account, language = "fr").setCookies()

            val body: String = client.get("/api/user") { sendCookies(cookies) }.bodyAsText()

            assertMatchesFixture("user/user.owner.derived.json", body)
            assertTrue(body.contains(""""_id":"${sessionUser(cookies)}""""))
            assertTrue(body.contains(""""username":"${account.username}""""))
            assertTrue(body.contains(""""language":"fr""""))
            assertTrue(body.contains(""""validEmail":false"""))
            assertTrue(Regex(""""_rev":"1-[0-9a-f]{32}"""").containsMatchIn(body))
        }
}
