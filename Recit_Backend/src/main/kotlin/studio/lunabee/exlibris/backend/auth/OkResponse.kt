package studio.lunabee.exlibris.backend.auth

import kotlinx.serialization.Serializable

/** inventaire.io's `{"ok":true}`, what a write with nothing else to say answers. */
@Serializable
data class OkResponse(
    val ok: Boolean = true,
)
