package studio.lunabee.exlibris.backend.entities

import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpStatusCode
import io.ktor.utils.io.ByteReadChannel

/** inventaire.io's answer as it goes back to the app: its status, the headers kept, its body still streaming. */
data class RelayedAnswer(
    val status: HttpStatusCode,
    val contentType: ContentType?,
    val contentLength: Long?,
    val headers: Headers,
    val body: ByteReadChannel,
)
