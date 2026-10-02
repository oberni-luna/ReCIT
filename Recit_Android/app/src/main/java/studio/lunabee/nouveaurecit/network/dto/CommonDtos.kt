package studio.lunabee.nouveaurecit.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OkStatusDto(val ok: Boolean = false)

/** The shape of an inventaire.io error body. `message` is English prose and is never rendered. */
@Serializable
data class ErrorBodyDto(
    val message: String? = null,
    @SerialName("error_name") val errorName: String? = null,
)

@Serializable
data class IdsPayload(val ids: List<String>)

@Serializable
data class SingleIdsPayload(val ids: String)
