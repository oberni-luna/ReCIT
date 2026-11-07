package studio.lunabee.exlibris.backend.auth

import io.ktor.client.request.forms.submitForm
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.http.parameters
import studio.lunabee.exlibris.backend.FixtureAssertions.assertMatchesFixture
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ResetPasswordRoutesTest {
    @Test
    fun `the mailed link opens a form whose new password signs in, once`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account)

            val request = client.postJson("/api/auth/reset-password", """{"email":"${account.email}"}""")

            assertEquals(HttpStatusCode.OK, request.status)
            assertMatchesFixture("auth/ok.derived.json", request.bodyAsText())
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/reset-password")
            val form: String = client.get(link).bodyAsText()
            assertTrue(form.contains("<h1>New password</h1>"))
            val saved: String = submit(link, "a new passphrase", "a new passphrase")
            assertTrue(saved.contains("Password changed."))
            assertEquals(HttpStatusCode.OK, client.login(account.username, password = "a new passphrase").status)
            assertTrue(client.get(link).bodyAsText().contains("This link no longer works."))
            assertTrue(submit(link, "another passphrase", "another passphrase").contains("This link no longer works."))
        }

    @Test
    fun `two different passwords, or a short one, show the form again with why`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account, language = "fr-FR,fr;q=0.9")
            client.postJson("/api/auth/reset-password", """{"email":"${account.email}"}""")
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/reset-password")

            assertTrue(
                submit(link, "a new passphrase", "another one").contains("Les deux mots de passe sont différents."),
            )
            assertTrue(submit(link, "short", "short").contains("Il faut entre 8 et 256 caractères."))
            assertTrue(submit(link, "a new passphrase", "a new passphrase").contains("Mot de passe modifié."))
        }

    @Test
    fun `a reset link opens for an hour`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            val userId: String? = sessionUser(client.signup(account).setCookies())
            client.postJson("/api/auth/reset-password", """{"email":"${account.email}"}""")
            val link: String = AuthTestEnvironment.mailedLink(account.email, "/reset-password")
            val lifetime: Long =
                AuthTestEnvironment.queryLong(
                    "SELECT expires_at - (extract(epoch FROM now()) * 1000)::bigint FROM user_tokens " +
                        "WHERE user_id = '$userId' AND purpose = 'password_reset'",
                )
            assertTrue(lifetime in (ONE_HOUR_MILLIS - TOLERANCE_MILLIS)..ONE_HOUR_MILLIS)

            AuthTestEnvironment.execute("UPDATE user_tokens SET expires_at = 0 WHERE user_id = '$userId'")

            assertTrue(client.get(link).bodyAsText().contains("This link no longer works."))
        }

    @Test
    fun `an unknown address answers what inventaire answers`() =
        authTest {
            val response = client.postJson("/api/auth/reset-password", """{"email":"nobody-at-all@example.org"}""")

            assertEquals(HttpStatusCode.BadRequest, response.status)
            assertMatchesFixture("auth/reset-password.unknown.derived.json", response.bodyAsText())
        }

    @Test
    fun `a fourth request in an hour for one address is refused with 429`() =
        authTest {
            val account: TestAccount = AuthTestEnvironment.newAccount()
            client.signup(account)
            repeat(3) {
                assertEquals(
                    HttpStatusCode.OK,
                    client.postJson("/api/auth/reset-password", """{"email":"${account.email}"}""").status,
                )
            }

            val response = client.postJson("/api/auth/reset-password", """{"email":"${account.email.uppercase()}"}""")

            assertEquals(HttpStatusCode.TooManyRequests, response.status)
        }

    private suspend fun io.ktor.server.testing.ApplicationTestBuilder.submit(
        link: String,
        password: String,
        confirmation: String,
    ): String =
        client
            .submitForm(
                url = "/reset-password",
                formParameters =
                    parameters {
                        append("token", link.substringAfter("token="))
                        append("password", password)
                        append("confirmation", confirmation)
                    },
            ).bodyAsText()

    private companion object {
        const val ONE_HOUR_MILLIS: Long = 3_600_000
        const val TOLERANCE_MILLIS: Long = 60_000
    }
}
