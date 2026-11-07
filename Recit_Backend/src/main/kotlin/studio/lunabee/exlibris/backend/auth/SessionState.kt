package studio.lunabee.exlibris.backend.auth

/** Where a call's session stands, and so which `Set-Cookie` headers its answer carries ([SessionCodec]). */
sealed interface SessionState {
    val payload: SessionPayload?

    /** The request's own session, valid: nothing to send, unless an older secret signed it. */
    data class Kept(
        override val payload: SessionPayload,
        val signedWithOlderSecret: Boolean,
    ) : SessionState

    /** A session to send: a fresh anonymous one, or one that names the user who just signed in. */
    data class Written(
        override val payload: SessionPayload,
    ) : SessionState

    /** Signed out, or past its max age: both cookies are sent back expired. */
    data object Removed : SessionState {
        override val payload: SessionPayload? = null
    }
}
