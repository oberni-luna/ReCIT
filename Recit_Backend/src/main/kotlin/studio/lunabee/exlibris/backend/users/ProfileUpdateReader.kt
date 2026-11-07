package studio.lunabee.exlibris.backend.users

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.intOrNull
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/**
 * `PUT /api/user`'s `{attribute, value}` read as inventaire.io's `controllers/user/update.ts` reads it, with its
 * refusals: a `null` only for `picture` and `position`, `403 forbidden update` for an attribute it does not let a
 * user change, `invalid value` for a value of the wrong shape. Whether the username or the address is free is the
 * service's question, not this one's.
 */
object ProfileUpdateReader {
    private const val BIO_MAX_LENGTH: Int = 1000
    private const val SETTINGS_PREFIX: String = "settings."
    private val languagePattern: Regex = Regex("^[a-zA-Z-]{2,10}$")
    private val picturePattern: Regex = Regex("^/img/users/[0-9a-f]{40}$")
    private val nullableAttributes: Set<String> = setOf("picture", "position")

    fun read(
        attribute: String,
        value: JsonElement?,
    ): ProfileUpdate {
        if ((value == null || value is JsonNull) && attribute !in nullableAttributes) {
            throw ApiException.missingParameter(ParameterPlace.BODY, "value")
        }
        val element: JsonElement = value ?: JsonNull
        return if (attribute.startsWith(SETTINGS_PREFIX)) setting(attribute, element) else attribute(attribute, element)
    }

    private fun attribute(
        attribute: String,
        value: JsonElement,
    ): ProfileUpdate =
        when (attribute) {
            "username" -> {
                ProfileUpdate.Username(string(value) ?: throw ApiException.invalidParameter("username"))
            }

            "email" -> {
                ProfileUpdate.Email(string(value) ?: throw ApiException.invalidParameter("email"))
            }

            "language" -> {
                ProfileUpdate.Language(valid(value, string(value)?.takeIf(languagePattern::matches)))
            }

            "bio" -> {
                ProfileUpdate.Bio(valid(value, string(value)?.takeIf { it.length <= BIO_MAX_LENGTH }))
            }

            "picture" -> {
                ProfileUpdate.Picture(nullable(value) { string(it)?.takeIf(picturePattern::matches) })
            }

            "position" -> {
                ProfileUpdate.Position(nullable(value, UserPosition::fromJson))
            }

            "fediversable" -> {
                ProfileUpdate.Fediversable(valid(value, literal(value)?.booleanOrNull))
            }

            "summaryPeriodicity" -> {
                ProfileUpdate.SummaryPeriodicity(valid(value, literal(value)?.intOrNull?.takeIf { it >= 1 }))
            }

            else -> {
                throw ApiException(HttpStatusCode.Forbidden, "forbidden update")
            }
        }

    private fun setting(
        attribute: String,
        value: JsonElement,
    ): ProfileUpdate {
        val name: String = attribute.removePrefix(SETTINGS_PREFIX)
        if (name !in UserSettingNames.all) throw ApiException.invalidParameter("attribute", attribute)
        return ProfileUpdate.Setting(name, valid(value, literal(value)?.booleanOrNull))
    }

    private fun <T : Any> valid(
        value: JsonElement,
        read: T?,
    ): T = read ?: throw invalidValue(value)

    /** A `null` value, or one [read] accepts. */
    private fun <T : Any> nullable(
        value: JsonElement,
        read: (JsonElement) -> T?,
    ): T? = if (value is JsonNull) null else valid(value, read(value))

    private fun string(value: JsonElement): String? = (value as? JsonPrimitive)?.takeIf { it.isString }?.content

    /** A number or a boolean, not the same written as a string. */
    private fun literal(value: JsonElement): JsonPrimitive? =
        (value as? JsonPrimitive)?.takeIf { !it.isString && it !is JsonNull }

    /** inventaire.io's `newInvalidError('value', value)`: a string is quoted as is, anything else as JSON. */
    private fun invalidValue(value: JsonElement): ApiException =
        ApiException.invalidParameter("value", string(value) ?: value.toString())
}
