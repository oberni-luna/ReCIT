package studio.lunabee.exlibris.backend.items

import io.ktor.http.HttpStatusCode
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.db.Visibility
import studio.lunabee.exlibris.backend.groups.GroupsService
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * A book's, an étagère's or a list's `visibility` as sent, checked as inventaire.io checks it:
 * `isVisibilityKeyArray`, then `validateVisibilityKeys`, which wants the owner in every group a `group:<id>` names.
 */
class VisibilityValidator(
    private val groups: GroupsService,
) {
    /** [value]'s keys, kept in the order sent; absent or `null` is `[]`, the owner alone. */
    suspend fun read(
        value: JsonElement?,
        ownerId: String,
    ): List<String> {
        if (value == null || value is JsonNull) return emptyList()
        val keys: List<String> =
            (value as? JsonArray)
                ?.map { key -> (key as? JsonPrimitive)?.takeIf { it.isString && isKey(it.content) }?.content }
                ?.takeIf { keys -> keys.all { it != null } }
                ?.filterNotNull()
                ?: throw ApiException.invalidParameter("visibility", value.toString())
        val named: List<String> =
            keys.filter { it.startsWith(Visibility.GROUP_PREFIX) }.map { it.removePrefix(Visibility.GROUP_PREFIX) }
        if (named.isNotEmpty() && !groups.memberGroupIds(ownerId).containsAll(named)) {
            throw ApiException(HttpStatusCode.BadRequest, "user is not in that group")
        }
        return keys
    }

    /** inventaire.io's `isVisibilityKey`: one of the keywords, or `group:` and a group id. */
    fun isKey(key: String): Boolean =
        key in keywords ||
            (key.startsWith(Visibility.GROUP_PREFIX) && DocumentId.isValid(key.removePrefix(Visibility.GROUP_PREFIX)))

    private companion object {
        val keywords: Set<String> = setOf(Visibility.FRIENDS, Visibility.GROUPS, Visibility.PUBLIC)
    }
}
