package studio.lunabee.nouveaurecit.auth.model

/**
 * `Model/Authentication/SessionCookieScope.swift`: which cookies are the session of the backend this build talks
 * to. inventaire.io and the Ex-libris backend (`-e exLibrisBackend`) send the same two names, so a name alone
 * cannot say; the cookie's domain has to match the base URL's host.
 */
object SessionCookieScope {
    /** RFC 6265's domain match: the cookie's domain, with or without its leading dot, is [host] or a parent of it. */
    fun covers(cookieDomain: String, host: String): Boolean {
        val domain: String = cookieDomain.lowercase().removePrefix(".")
        val target: String = host.lowercase()
        return domain.isNotEmpty() && (target == domain || target.endsWith(".$domain"))
    }
}
