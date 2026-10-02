package studio.lunabee.nouveaurecit.auth

import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl

/**
 * The jar — `HTTPCookieStorage.shared` in ADR 0008: what actually gets sent on every request of the
 * authenticated client. In memory; the vault is the record that survives a relaunch, and
 * `AuthService` restores the jar from it at start.
 */
class SessionCookieJar(private val clock: () -> Long = System::currentTimeMillis) : CookieJar {
    private val cookies: MutableList<Cookie> = mutableListOf()

    @Synchronized
    override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
        for (cookie in cookies) {
            this.cookies.removeAll { it.name == cookie.name && it.domain == cookie.domain && it.path == cookie.path }
            if (cookie.expiresAt > clock()) this.cookies += cookie
        }
    }

    @Synchronized
    override fun loadForRequest(url: HttpUrl): List<Cookie> {
        val now: Long = clock()
        cookies.removeAll { it.expiresAt <= now }
        return cookies.filter { it.matches(url) }
    }

    @Synchronized
    fun all(): List<Cookie> = cookies.toList()

    @Synchronized
    fun put(cookie: Cookie) {
        saveFromResponse(HttpUrl.Builder().scheme("https").host(cookie.domain).build(), listOf(cookie))
    }

    @Synchronized
    fun remove(names: Set<String>) {
        cookies.removeAll { it.name in names }
    }
}
