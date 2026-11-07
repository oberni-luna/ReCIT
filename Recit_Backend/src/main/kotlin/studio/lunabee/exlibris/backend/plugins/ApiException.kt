package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode

/** Thrown by a service to answer [status] with [verbose] as `status_verbose`; see [installStatusPages]. */
class ApiException(
    val status: HttpStatusCode,
    val verbose: String,
) : RuntimeException(verbose)
