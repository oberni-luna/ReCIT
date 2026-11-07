package studio.lunabee.exlibris.backend.plugins

import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.calllogging.CallLogging
import io.ktor.server.plugins.calllogging.processingTimeMillis
import io.ktor.server.request.httpMethod
import io.ktor.server.request.path
import org.slf4j.event.Level

/** One line per request: `GET /health 200 4ms`. */
fun Application.installRequestLogging() {
    install(CallLogging) {
        level = Level.INFO
        format { call ->
            val status: Int? = call.response.status()?.value
            "${call.request.httpMethod.value} ${call.request.path()} $status ${call.processingTimeMillis()}ms"
        }
    }
}
