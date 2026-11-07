package studio.lunabee.exlibris.backend.plugins

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * inventaire.io's error shape, the one the apps read: `{"status":400,"message":"invalid email: x",
 * "error_type":"invalid_parameter","error_name":"invalid_email"}`. `status_verbose` repeats `message`, as the
 * skeleton (#69) answered. inventaire.io's `context`, debugging data the apps never read, is not reproduced.
 */
@Serializable
data class ErrorBody(
    val status: Int,
    @SerialName("status_verbose")
    val statusVerbose: String,
    val message: String = statusVerbose,
    @SerialName("error_type")
    val errorType: String? = null,
    @SerialName("error_name")
    val errorName: String? = null,
)
