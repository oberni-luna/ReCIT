package studio.lunabee.exlibris.backend.auth

import io.ktor.server.config.ApplicationConfig
import java.time.Duration

/**
 * How sessions are signed and sent. [secrets] are newest first (see [Keygrip]); [secure] adds `Secure` to the
 * cookies, which inventaire.io does when its public protocol is HTTPS — a local HTTP backend would otherwise
 * set cookies no client sends back.
 */
data class SessionConfig(
    val secrets: List<String>,
    val secure: Boolean,
) {
    init {
        require(secrets.isNotEmpty()) { "session.secrets is empty" }
        require(!(secure && DEVELOPMENT_SECRET in secrets)) { "SESSION_SECRET must be set behind HTTPS" }
    }

    companion object {
        /** inventaire.io's `cookieMaxAge`: six months, on the cookie and on the session's own timestamp. */
        val MAX_AGE: Duration = Duration.ofDays(180)

        private const val DEVELOPMENT_SECRET: String = "local-development-only"

        fun from(config: ApplicationConfig): SessionConfig =
            SessionConfig(
                secrets =
                    config
                        .property("session.secrets")
                        .getString()
                        .split(",")
                        .map(String::trim)
                        .filter(String::isNotEmpty),
                secure = config.property("public.baseUrl").getString().startsWith("https://"),
            )
    }
}
