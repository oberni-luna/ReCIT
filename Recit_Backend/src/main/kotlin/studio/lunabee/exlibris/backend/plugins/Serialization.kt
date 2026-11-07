package studio.lunabee.exlibris.backend.plugins

import io.ktor.serialization.kotlinx.json.DefaultJson
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import kotlinx.serialization.json.Json

/**
 * What every answer is written with: an absent value leaves its key out, as `JSON.stringify` drops inventaire.io's
 * `undefined`s. Also what a service encodes a document with when it answers documents of mixed shapes.
 */
val apiJson: Json = Json(DefaultJson) { explicitNulls = false }

fun Application.installSerialization() {
    install(ContentNegotiation) {
        json(apiJson)
    }
}
