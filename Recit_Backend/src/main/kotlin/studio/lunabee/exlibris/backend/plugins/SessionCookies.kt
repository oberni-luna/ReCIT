package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationCall
import io.ktor.server.application.createApplicationPlugin
import io.ktor.server.application.install
import io.ktor.util.AttributeKey
import studio.lunabee.exlibris.backend.auth.SessionCodec
import studio.lunabee.exlibris.backend.auth.SessionState

private val callSessionKey: AttributeKey<CallSession> = AttributeKey("CallSession")

/**
 * inventaire.io's global `cookie-session` middleware: every call opens the request's session, or an anonymous
 * one, and its answer — a route's, an error's, a rate limit's — carries whatever the session became.
 */
fun Application.installSessionCookies(codec: SessionCodec) {
    install(
        createApplicationPlugin("SessionCookies") {
            onCall { call ->
                val cookies: Map<String, String> = call.request.cookies.rawCookies
                val state: SessionState =
                    codec.open(
                        cookies[SessionCodec.COOKIE_NAME],
                        cookies[SessionCodec.SIGNATURE_COOKIE_NAME],
                    )
                call.attributes.put(callSessionKey, CallSession(codec, state))
            }
            onCallRespond { call, _ ->
                val session: CallSession? = call.attributes.getOrNull(callSessionKey)
                if (session != null && !session.isSent) {
                    session.isSent = true
                    val headers: List<String> = codec.setCookieHeaders(session.state)
                    headers.forEach { call.response.headers.append(HttpHeaders.SetCookie, it) }
                }
            }
        },
    )
}

/** The signed-in user's id, or `null` for an anonymous session. */
val ApplicationCall.sessionUserId: String?
    get() =
        attributes
            .getOrNull(callSessionKey)
            ?.state
            ?.payload
            ?.user

/** The signed-in user's id; an anonymous call is refused as inventaire.io refuses it. */
fun ApplicationCall.requireSessionUser(): String = sessionUserId ?: throw ApiException.unauthorized()

/** Answers with a session naming [userId]: what signing in, or signing up, hands the client. */
fun ApplicationCall.openUserSession(userId: String) {
    attributes[callSessionKey].let { it.state = it.codec.signedIn(userId) }
}

/** Answers with both session cookies expired. */
fun ApplicationCall.closeSession() {
    attributes[callSessionKey].state = SessionState.Removed
}

private class CallSession(
    val codec: SessionCodec,
    var state: SessionState,
) {
    var isSent: Boolean = false
}
