package studio.lunabee.exlibris.backend.health

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException

class HealthService(
    private val repository: HealthRepository,
) {
    suspend fun check(): HealthReport {
        if (!repository.isDatabaseReachable()) {
            throw ApiException(HttpStatusCode.ServiceUnavailable, "database unreachable")
        }
        return HealthReport.OK
    }
}
