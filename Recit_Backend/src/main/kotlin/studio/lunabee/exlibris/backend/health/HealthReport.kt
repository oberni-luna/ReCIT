package studio.lunabee.exlibris.backend.health

import kotlinx.serialization.Serializable

@Serializable
data class HealthReport(
    val status: String,
    val db: String,
) {
    companion object {
        val OK: HealthReport = HealthReport(status = "ok", db = "ok")
    }
}
