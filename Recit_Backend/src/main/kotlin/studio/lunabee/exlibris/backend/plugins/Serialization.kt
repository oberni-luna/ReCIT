package studio.lunabee.exlibris.backend.plugins

import io.ktor.serialization.kotlinx.json.DefaultJson
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import kotlinx.serialization.json.Json

/** An absent value leaves its key out, as `JSON.stringify` drops inventaire.io's `undefined`s. */
fun Application.installSerialization() {
    install(ContentNegotiation) {
        json(Json(DefaultJson) { explicitNulls = false })
    }
}
