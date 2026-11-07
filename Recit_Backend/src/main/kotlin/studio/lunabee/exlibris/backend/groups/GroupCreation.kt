package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import studio.lunabee.exlibris.backend.plugins.JsonBody
import studio.lunabee.exlibris.backend.users.UserPosition

/**
 * `POST /api/groups`' body, read as inventaire.io's `create.ts` reads it: a `name`, the rest optional — `searchable`
 * on and `open` off unless said otherwise —, each checked as `update-settings` would check it.
 */
data class GroupCreation(
    val name: String,
    val description: String,
    val searchable: Boolean,
    val open: Boolean,
    val position: UserPosition?,
) {
    companion object {
        fun from(body: JsonBody): GroupCreation {
            val name: String = body.string("name")
            if (!GroupSlug.isValidName(name)) throw GroupSettingReader.invalid("name", body.element("name") ?: JsonNull)
            return GroupCreation(
                name = name,
                description = body.present("description")?.let(::description).orEmpty(),
                searchable = body.present("searchable")?.let { boolean("searchable", it) } ?: true,
                open = body.present("open")?.let { boolean("open", it) } ?: false,
                position = body.present("position")?.let(::position),
            )
        }

        private fun JsonBody.present(name: String): JsonElement? = element(name)?.takeIf { it !is JsonNull }

        private fun description(value: JsonElement): String =
            GroupSettingReader.description(value) ?: throw GroupSettingReader.invalid("description", value)

        private fun boolean(
            name: String,
            value: JsonElement,
        ): Boolean = GroupSettingReader.boolean(value) ?: throw GroupSettingReader.invalid(name, value)

        private fun position(value: JsonElement): UserPosition? =
            GroupSettingReader.position(value)?.position ?: throw GroupSettingReader.invalid("position", value)
    }
}
