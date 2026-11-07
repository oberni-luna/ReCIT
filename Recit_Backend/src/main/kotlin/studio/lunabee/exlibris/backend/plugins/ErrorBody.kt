package studio.lunabee.exlibris.backend.plugins

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** inventaire.io's error shape, the one the apps read: `{"status":404,"status_verbose":"not found"}`. */
@Serializable
data class ErrorBody(
    val status: Int,
    @SerialName("status_verbose")
    val statusVerbose: String,
)
