package studio.lunabee.exlibris.backend.groups

import kotlinx.serialization.Serializable

/** `PUT /api/groups/update-settings`: `ok`, and the slug a new name moved to, under `update`. */
@Serializable
data class GroupSettingsUpdate(
    val ok: Boolean = true,
    val update: Map<String, String>,
)
