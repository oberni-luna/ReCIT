package studio.lunabee.exlibris.backend.auth

import io.ktor.server.html.respondHtml
import io.ktor.server.plugins.ratelimit.rateLimit
import io.ktor.server.request.acceptLanguage
import io.ktor.server.request.receiveParameters
import io.ktor.server.response.respond
import io.ktor.server.response.respondRedirect
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.put
import io.ktor.server.routing.route
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.RateLimits
import studio.lunabee.exlibris.backend.plugins.closeSession
import studio.lunabee.exlibris.backend.plugins.openUserSession
import studio.lunabee.exlibris.backend.plugins.queryParameter
import studio.lunabee.exlibris.backend.plugins.receiveJsonBody
import studio.lunabee.exlibris.backend.plugins.requireSessionUser

/** inventaire.io's `/api/auth/…` that the apps call, and the pages the account e-mails' links open. */
fun Route.authRoutes(
    auth: AuthService,
    links: AccountLinkService,
) {
    route("/api/auth") {
        sessionRoutes(auth)
        availabilityRoutes(auth)
        accountRoutes(auth, links)
    }
    accountPageRoutes(links)
}

private fun Route.sessionRoutes(auth: AuthService) {
    rateLimit(RateLimits.SIGNUP) {
        post("signup") {
            val body: JsonBody = call.receiveJsonBody()
            val userId: String =
                auth.signup(
                    username = body.string("username"),
                    email = body.string("email"),
                    password = body.string("password"),
                    language = AccountRules.languageCode(call.request.acceptLanguage()),
                )
            call.openUserSession(userId)
            call.respond(OkResponse())
        }
    }
    rateLimit(RateLimits.LOGIN) {
        post("login") {
            val body: JsonBody = call.receiveJsonBody()
            call.openUserSession(auth.login(body.string("username"), body.string("password")))
            call.respond(OkResponse())
        }
    }
    // inventaire.io sends the browser back to its landing page; the apps ignore where it points.
    post("logout") {
        call.closeSession()
        call.respondRedirect("/")
    }
}

private fun Route.availabilityRoutes(auth: AuthService) {
    get("username-availability") {
        call.respond(
            UsernameAvailability(auth.checkAvailability(AccountField.USERNAME, call.queryParameter("username"))),
        )
    }
    get("email-availability") {
        call.respond(EmailAvailability(auth.checkAvailability(AccountField.EMAIL, call.queryParameter("email"))))
    }
}

private fun Route.accountRoutes(
    auth: AuthService,
    links: AccountLinkService,
) {
    put("password") {
        val userId: String = call.requireSessionUser()
        val body: JsonBody = call.receiveJsonBody()
        auth.changePassword(userId, body.string("old-password"), body.string("new-password"))
        call.respond(OkResponse())
    }
    post("reset-password") {
        links.requestPasswordReset(call.receiveJsonBody().string("email"))
        call.respond(OkResponse())
    }
    post("email-confirmation") {
        links.requestEmailConfirmation(call.requireSessionUser())
        call.respond(OkResponse())
    }
}

/** Always `200`: a page is read by a person, and an error status would hand it to `StatusPages`' JSON. */
private fun Route.accountPageRoutes(links: AccountLinkService) {
    get("/confirm-email") {
        val account: Account? = call.request.queryParameters["token"]?.let { links.confirmEmail(it) }
        val page: AccountPage = if (account == null) AccountPage.ConfirmationLinkInvalid else AccountPage.EmailConfirmed
        call.respondHtml { accountPage(AccountLanguage.of(account?.language ?: call.request.acceptLanguage()), page) }
    }
    get("/reset-password") {
        val token: String = call.request.queryParameters["token"].orEmpty()
        val account: Account? = links.passwordResetAccount(token)
        val page: AccountPage =
            if (account ==
                null
            ) {
                AccountPage.ResetLinkInvalid
            } else {
                AccountPage.ResetForm(token, problem = null)
            }
        call.respondHtml { accountPage(AccountLanguage.of(account?.language ?: call.request.acceptLanguage()), page) }
    }
    post("/reset-password") {
        val form = call.receiveParameters()
        val token: String = form["token"].orEmpty()
        val account: Account? = links.passwordResetAccount(token)
        val page: AccountPage =
            if (account == null) {
                AccountPage.ResetLinkInvalid
            } else {
                when (
                    val reset =
                        links.resetPassword(
                            token,
                            form["password"].orEmpty(),
                            form["confirmation"].orEmpty(),
                        )
                ) {
                    PasswordReset.DONE -> AccountPage.PasswordChanged
                    PasswordReset.INVALID_LINK -> AccountPage.ResetLinkInvalid
                    PasswordReset.MISMATCH, PasswordReset.INVALID_PASSWORD -> AccountPage.ResetForm(token, reset)
                }
            }
        call.respondHtml { accountPage(AccountLanguage.of(account?.language ?: call.request.acceptLanguage()), page) }
    }
}
