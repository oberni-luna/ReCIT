package studio.lunabee.exlibris.backend.auth

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.text.Normalizer

/**
 * inventaire.io's rules for an account (`server/lib/regex.ts`, `server/models/validations/user.ts`,
 * `server/controllers/user/lib/is_reserved_word.ts`), and the refusals it answers when one is broken. The apps
 * restate none of them: the availability checks and `AuthFailure.classifySignup` read these answers.
 */
object AccountRules {
    /** Every one-letter name is reserved for inventaire.io's own paths, hence the minimum of two. */
    private val usernamePattern: Regex = Regex("""^[\p{L}\p{N}_]{2,20}$""")

    /** The WHATWG `type=email` pattern, as inventaire.io copied it. */
    private val emailPattern: Regex =
        Regex(
            """^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?""" +
                """(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$""",
        )

    private val languagePattern: Regex = Regex("^[a-zA-Z-]{2,10}$")

    /** Bounded above so that hashing a megabyte-long password cannot exhaust the server. */
    private const val PASSWORD_MIN_LENGTH: Int = 8
    private const val PASSWORD_MAX_LENGTH: Int = 256
    private val passwordLength: IntRange = PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH

    /** inventaire.io's list, its databases' names singularized included. */
    private val reservedWords: Set<String> =
        setOf(
            "activitie",
            "comment",
            "element",
            "entitie",
            "group",
            "image",
            "instances_subscription",
            "item",
            "list",
            "notification",
            "oauth_authorization",
            "oauth_client",
            "oauth_token",
            "patche",
            "relation",
            "shelve",
            "task",
            "transaction",
            "user",
            "api",
            "auth",
            "client",
            "contact",
            "contribute",
            "donate",
            "ean",
            "email",
            "exchange",
            "feedback",
            "friend",
            "give",
            "instance",
            "inv",
            "inventories",
            "inventorize",
            "inventory",
            "invite",
            "invited",
            "isbn",
            "key",
            "last",
            "latest",
            "lend",
            "local",
            "map",
            "me",
            "nearby",
            "network",
            "oauth",
            "private",
            "profil",
            "profile",
            "public",
            "self",
            "sell",
            "server",
            "setting",
            "share",
            "username",
            "value",
            "wd",
            "welcome",
            "wikidata",
        )

    /** inventaire.io's `normalizeString`, applied to a username before anything else. */
    fun normalizeUsername(username: String): String = Normalizer.normalize(username.trim(), Normalizer.Form.NFC)

    fun isEmail(value: String): Boolean = emailPattern.matches(value)

    fun isPassword(value: String): Boolean = value.length in passwordLength

    fun usernameRefusal(username: String): ApiException? =
        when {
            !usernamePattern.matches(username) -> ApiException.invalidParameter("username", username)
            isReserved(username) -> ApiException(HttpStatusCode.BadRequest, "reserved words can't be usernames")
            else -> null
        }

    /** What `/auth/login` accepts as its `username`: a username's shape, or an address. */
    fun loginRefusal(login: String): ApiException? =
        if (usernamePattern.matches(login) || isEmail(login)) null else ApiException.invalidParameter("username", login)

    fun emailRefusal(email: String): ApiException? =
        if (isEmail(email)) null else ApiException.invalidParameter("email", email)

    /** The password itself stays out of the message, which inventaire.io would echo. */
    fun passwordRefusal(
        parameter: String,
        password: String,
    ): ApiException? = if (isPassword(password)) null else ApiException.invalidParameter(parameter)

    /** The account's language, from `Accept-Language`'s first tag, English when it names none. */
    fun languageCode(acceptLanguage: String?): String =
        acceptLanguage
            ?.substringBefore(',')
            ?.substringBefore(';')
            ?.substringBefore('-')
            ?.trim()
            ?.lowercase()
            ?.takeIf(languagePattern::matches)
            ?: "en"

    private fun isReserved(username: String): Boolean {
        val lowercased: String = username.lowercase()
        return lowercased in reservedWords || lowercased.removeSuffix("s") in reservedWords
    }
}
