package studio.lunabee.exlibris.backend.plugins

import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationCall
import io.ktor.server.application.install
import io.ktor.server.plugins.statuspages.StatusPages
import io.ktor.server.response.respond

private const val FIRST_ERROR_STATUS: Int = 400

/**
 * Every error leaves in [ErrorBody]'s shape, whether a service threw it or Ktor answered it alone; a relayed
 * call's error is inventaire.io's, and leaves as inventaire.io wrote it ([markRelayed]).
 */
fun Application.installStatusPages() {
    install(StatusPages) {
        exception<ApiException> { call, cause ->
            call.respond(
                cause.status,
                ErrorBody(cause.status.value, cause.verbose, errorType = cause.errorType, errorName = cause.errorName),
            )
        }
        HttpStatusCode.allStatusCodes
            .filter { it.value >= FIRST_ERROR_STATUS }
            .forEach { errorStatus ->
                status(errorStatus) { call, status -> if (!call.isRelayed) call.respondError(status) }
            }
    }
}

private suspend fun ApplicationCall.respondError(
    status: HttpStatusCode,
    verbose: String = status.description.lowercase(),
) {
    respond(status, ErrorBody(status.value, verbose))
}
