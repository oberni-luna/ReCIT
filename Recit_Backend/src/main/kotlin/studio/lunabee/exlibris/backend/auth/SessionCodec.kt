package studio.lunabee.exlibris.backend.auth

import kotlinx.serialization.json.Json
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Base64
import java.util.Locale

/**
 * inventaire.io's session, as `cookie-session` + `cookies` + `keygrip` write it and `enforceSessionMaxAge`
 * polices it, so `AuthService` and ADR 0008 work against this backend unchanged:
 *
 * - `inventaire:session` is the payload's JSON in unpadded base64url; `inventaire:session.sig` is [Keygrip]'s
 *   signature of `inventaire:session=<value>`.
 * - A request without a valid pair — no cookie, a tampered signature, an unreadable payload — starts an
 *   anonymous session, sent back with the answer: every public call hands one out.
 * - A session past [SessionConfig.MAX_AGE], counted from its timestamp, is closed.
 *
 * Two departures. `cookie-session` writes standard base64, whose `+` and `/` Android's `SessionCookie` cannot
 * read; base64url can be read by both apps, and is read here as well as the standard alphabet. And inventaire.io
 * re-signs a session signed by an older secret with a bare `.sig` cookie, path and `HttpOnly` only, which a
 * client then keeps until it quits; here both cookies are sent again, whole.
 */
class SessionCodec(
    private val config: SessionConfig,
    private val clock: Clock,
) {
    private val keygrip: Keygrip = Keygrip(config.secrets)

    /** The session a request starts with, read from its two cookies' raw values. */
    fun open(
        value: String?,
        signature: String?,
    ): SessionState {
        val now: Long = clock.millis()
        val verified: VerifiedSession? = verify(value, signature)
        val timestamp: Long? = verified?.payload?.timestamp
        return when {
            verified == null -> SessionState.Written(SessionPayload(timestamp = now))
            timestamp == null -> SessionState.Written(verified.payload.copy(timestamp = now))
            now - timestamp > SessionConfig.MAX_AGE.toMillis() -> SessionState.Removed
            else -> SessionState.Kept(verified.payload, signedWithOlderSecret = verified.secretIndex > 0)
        }
    }

    fun signedIn(userId: String): SessionState =
        SessionState.Written(SessionPayload(user = userId, timestamp = clock.millis()))

    /** The `Set-Cookie` header values that put [state] on the client. */
    fun setCookieHeaders(state: SessionState): List<String> =
        when (state) {
            is SessionState.Kept -> if (state.signedWithOlderSecret) cookiePair(encode(state.payload)) else emptyList()
            is SessionState.Written -> cookiePair(encode(state.payload))
            SessionState.Removed -> cookiePair(value = "", expires = Instant.EPOCH)
        }

    private fun verify(
        value: String?,
        signature: String?,
    ): VerifiedSession? {
        val secretIndex: Int? =
            if (value.isNullOrEmpty() || signature == null) null else keygrip.index("$COOKIE_NAME=$value", signature)
        val payload: SessionPayload? = if (secretIndex != null && value != null) decode(value) else null
        return if (secretIndex != null && payload != null) VerifiedSession(payload, secretIndex) else null
    }

    private fun cookiePair(
        value: String,
        expires: Instant = clock.instant().plus(SessionConfig.MAX_AGE),
    ): List<String> {
        val secure: String = if (config.secure) "; secure" else ""
        val attributes = "; path=/; expires=${HTTP_DATE.format(expires)}; samesite=lax$secure; httponly"
        return listOf(
            "$COOKIE_NAME=$value$attributes",
            "$SIGNATURE_COOKIE_NAME=${keygrip.sign("$COOKIE_NAME=$value")}$attributes",
        )
    }

    private fun encode(payload: SessionPayload): String =
        Base64
            .getUrlEncoder()
            .withoutPadding()
            .encodeToString(json.encodeToString(SessionPayload.serializer(), payload).toByteArray())

    /** Node's `Buffer.from(value, 'base64')`, which takes base64url and missing padding as well. */
    private fun decode(value: String): SessionPayload? {
        val base64: String = value.replace('-', '+').replace('_', '/').trimEnd('=')
        val padded: String = base64.padEnd((base64.length + BASE64_QUANTUM - 1) / BASE64_QUANTUM * BASE64_QUANTUM, '=')
        return try {
            json.decodeFromString(SessionPayload.serializer(), Base64.getDecoder().decode(padded).decodeToString())
        } catch (error: IllegalArgumentException) {
            logger.debug("Unreadable session payload: {}", error.message)
            null
        }
    }

    private data class VerifiedSession(
        val payload: SessionPayload,
        val secretIndex: Int,
    )

    companion object {
        const val COOKIE_NAME: String = "inventaire:session"
        const val SIGNATURE_COOKIE_NAME: String = "$COOKIE_NAME.sig"

        private const val BASE64_QUANTUM: Int = 4

        private val json: Json =
            Json {
                explicitNulls = false
                ignoreUnknownKeys = true
            }

        /** JavaScript's `toUTCString()`, which `cookies` writes: `Thu, 06 May 2027 09:31:53 GMT`. */
        private val HTTP_DATE: DateTimeFormatter =
            DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.US).withZone(ZoneOffset.UTC)

        private val logger: Logger = LoggerFactory.getLogger(SessionCodec::class.java)
    }
}
