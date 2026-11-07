package studio.lunabee.exlibris.backend.auth

import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class SessionCodecTest {
    private val secrets: List<String> = listOf("test-secret-new", "test-secret-old")

    @Test
    fun `a signed-in session is written as cookie-session writes it`() {
        val codec = codec(at = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP))

        val headers: List<String> = codec.setCookieHeaders(codec.signedIn(SessionVectors.USER_ID))

        val attributes = "; path=/; expires=Fri, 19 Feb 2027 13:55:40 GMT; samesite=lax; httponly"
        assertEquals(
            listOf(
                "inventaire:session=${SessionVectors.USER}$attributes",
                "inventaire:session.sig=${SessionVectors.USER_SIGNATURE}$attributes",
            ),
            headers,
        )
    }

    @Test
    fun `behind HTTPS the cookies are Secure`() {
        val codec = codec(at = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP), secure = true)

        val headers: List<String> = codec.setCookieHeaders(codec.signedIn(SessionVectors.USER_ID))

        assertTrue(headers.all { it.endsWith("; samesite=lax; secure; httponly") })
    }

    @Test
    fun `a valid pair is kept and nothing is sent back`() {
        val codec = codec(at = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP).plusSeconds(60))

        val state: SessionState = codec.open(SessionVectors.USER, SessionVectors.USER_SIGNATURE)

        assertEquals(
            SessionState.Kept(SessionPayload(SessionVectors.USER_ID, SessionVectors.USER_TIMESTAMP), false),
            state,
        )
        assertEquals(emptyList(), codec.setCookieHeaders(state))
    }

    @Test
    fun `a tampered signature makes the request anonymous`() {
        val now: Instant = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP).plusSeconds(60)
        val codec = codec(at = now)

        val state: SessionState = codec.open(SessionVectors.USER, SessionVectors.USER_SIGNATURE.replaceFirst('T', 'U'))

        assertEquals(SessionState.Written(SessionPayload(user = null, timestamp = now.toEpochMilli())), state)
    }

    @Test
    fun `a session without its signature, or without any cookie, is a new anonymous one`() {
        val now: Instant = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP)
        val codec = codec(at = now)
        val anonymous: SessionState = SessionState.Written(SessionPayload(timestamp = now.toEpochMilli()))

        assertEquals(anonymous, codec.open(SessionVectors.USER, signature = null))
        assertEquals(anonymous, codec.open(value = null, signature = null))
        val header: String = codec.setCookieHeaders(anonymous).first()
        assertTrue(header.startsWith("inventaire:session=eyJ0aW1lc3RhbXAiOjE3ODc0OTMzNDA3NjF9;"))
    }

    @Test
    fun `an anonymous session handed out by inventaire's codec is read back as nobody's`() {
        val codec = codec(at = Instant.ofEpochMilli(1_788_900_010_063).plusSeconds(1))

        val state: SessionState = codec.open(SessionVectors.ANONYMOUS, SessionVectors.ANONYMOUS_SIGNATURE)

        assertIs<SessionState.Kept>(state)
        assertEquals(null, state.payload.user)
    }

    @Test
    fun `a session signed by an older secret is sent again under the newest`() {
        val codec = codec(at = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP).plusSeconds(60))

        val state: SessionState = codec.open(SessionVectors.USER, SessionVectors.USER_SIGNATURE_OLD_SECRET)

        assertEquals(
            SessionState.Kept(SessionPayload(SessionVectors.USER_ID, SessionVectors.USER_TIMESTAMP), true),
            state,
        )
        assertTrue(
            codec.setCookieHeaders(state).last().startsWith("inventaire:session.sig=${SessionVectors.USER_SIGNATURE};"),
        )
    }

    @Test
    fun `six months after it opened, a session is closed with both cookies expired`() {
        val codec = codec(at = Instant.ofEpochMilli(SessionVectors.USER_TIMESTAMP).plus(Duration.ofDays(181)))

        val state: SessionState = codec.open(SessionVectors.USER, SessionVectors.USER_SIGNATURE)

        assertEquals(SessionState.Removed, state)
        val attributes = "; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=lax; httponly"
        assertEquals(
            listOf(
                "inventaire:session=$attributes",
                "inventaire:session.sig=${SessionVectors.EMPTY_SIGNATURE}$attributes",
            ),
            codec.setCookieHeaders(state),
        )
    }

    @Test
    fun `padded base64 and its url-safe spelling both decode, as Node's Buffer reads them`() {
        val signed = Keygrip(secrets)
        val codec = codec(at = Instant.ofEpochMilli(1_700_000_000_000).plusSeconds(1))
        val urlSafe: String = SessionVectors.PADDED.replace('+', '-').trimEnd('=')

        val padded: SessionState =
            codec.open(
                SessionVectors.PADDED,
                signed.sign("inventaire:session=${SessionVectors.PADDED}"),
            )
        val unpadded: SessionState = codec.open(urlSafe, signed.sign("inventaire:session=$urlSafe"))

        assertEquals("0123456789abcdef0123456789abcdef", padded.payload?.user)
        assertEquals(padded, unpadded)
    }

    private fun codec(
        at: Instant,
        secure: Boolean = false,
    ): SessionCodec = SessionCodec(SessionConfig(secrets, secure), Clock.fixed(at, ZoneOffset.UTC))
}
