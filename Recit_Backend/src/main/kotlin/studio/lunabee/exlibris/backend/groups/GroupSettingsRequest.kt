package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.json.JsonElement
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.plugins.ParameterPlace

/**
 * `update-settings`' body as inventaire.io's sanitizer lets it through, before the group is read: a group id, an
 * attribute of `updatable`, a `value` present, `null` included. Whether the value fits the attribute is checked
 * after the caller's right, by [GroupSettingReader].
 */
data class GroupSettingsRequest(
    val groupId: String,
    val attribute: String,
    val value: JsonElement,
) {
    companion object {
        fun from(body: JsonBody): GroupSettingsRequest {
            val groupId: String = body.string("group")
            if (!DocumentId.isValid(groupId)) throw ApiException.invalidParameter("group", groupId)
            val attribute: String = body.string("attribute")
            GroupSettingReader.requireUpdatable(attribute)
            return GroupSettingsRequest(
                groupId = groupId,
                attribute = attribute,
                value = body.element("value") ?: throw ApiException.missingParameter(ParameterPlace.BODY, "value"),
            )
        }
    }
}
