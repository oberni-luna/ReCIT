package studio.lunabee.exlibris.backend.plugins

import io.ktor.server.application.ApplicationCall
import io.ktor.util.AttributeKey

private val relayedCallKey: AttributeKey<Unit> = AttributeKey("RelayedCall")

/**
 * Marks a call answered with inventaire.io's own answer (#76): [installStatusPages] leaves an error body
 * inventaire.io wrote as it is, and [installSessionCookies] adds no `Set-Cookie` to it.
 */
fun ApplicationCall.markRelayed() {
    attributes.put(relayedCallKey, Unit)
}

val ApplicationCall.isRelayed: Boolean
    get() = attributes.contains(relayedCallKey)
