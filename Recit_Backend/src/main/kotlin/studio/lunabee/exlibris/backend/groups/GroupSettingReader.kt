package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.users.UserPosition

/**
 * `update-settings`' `{attribute, value}` read as inventaire.io's `lib/update_settings.ts` reads them: an attribute
 * of `updatable` only, a value `groupValidations` accepts, `null` for `picture` and `position` alone. Group creation
 * reads its fields with the same checks.
 */
object GroupSettingReader {
    const val DESCRIPTION_MAX_LENGTH: Int = 5000

    /** inventaire.io's `isGroupImg`. */
    private val picturePattern: Regex = Regex("^/img/groups/[0-9a-f]{40}$")

    private val updatable: List<String> = listOf("name", "picture", "description", "searchable", "position", "open")

    /** The sanitizer's allowlist, checked before the group is even read. */
    fun requireUpdatable(attribute: String) {
        if (attribute !in updatable) throw ApiException.invalidParameter("attribute", attribute)
    }

    fun read(
        attribute: String,
        value: JsonElement,
    ): GroupSetting {
        requireUpdatable(attribute)
        val setting: GroupSetting? =
            when (attribute) {
                "name" -> string(value)?.takeIf(GroupSlug::isValidName)?.let(GroupSetting::Name)
                "description" -> description(value)?.let(GroupSetting::Description)
                "searchable" -> boolean(value)?.let(GroupSetting::Searchable)
                "open" -> boolean(value)?.let(GroupSetting::Open)
                "picture" -> picture(value)
                else -> position(value)
            }
        return setting ?: throw invalid(attribute, value)
    }

    fun description(value: JsonElement): String? = string(value)?.takeIf { it.length <= DESCRIPTION_MAX_LENGTH }

    /** A JSON boolean, not the same written as a string. */
    fun boolean(value: JsonElement): Boolean? =
        (value as? JsonPrimitive)?.takeIf { !it.isString && it !is JsonNull }?.booleanOrNull

    /** `null` when [value] is not a position; a JSON `null` takes the position away. */
    fun position(value: JsonElement): GroupSetting.Position? =
        if (value is JsonNull) {
            GroupSetting.Position(
                null,
            )
        } else {
            UserPosition.fromJson(value)?.let(GroupSetting::Position)
        }

    /** inventaire.io's `newInvalidError(attribute, value)`: a string is quoted as is, anything else as JSON. */
    fun invalid(
        attribute: String,
        value: JsonElement,
    ): ApiException = ApiException.invalidParameter(attribute, string(value) ?: value.toString())

    private fun picture(value: JsonElement): GroupSetting.Picture? =
        if (value is JsonNull) {
            GroupSetting.Picture(null)
        } else {
            string(value)?.takeIf(picturePattern::matches)?.let(GroupSetting::Picture)
        }

    private fun string(value: JsonElement): String? = (value as? JsonPrimitive)?.takeIf { it.isString }?.content
}
