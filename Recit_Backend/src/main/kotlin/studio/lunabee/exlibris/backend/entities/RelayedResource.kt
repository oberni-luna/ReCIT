package studio.lunabee.exlibris.backend.entities

import io.ktor.http.HttpHeaders
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * What a relayed path serves, which sets how long inventaire.io is waited for and which of its headers come back
 * besides `Content-Type` (#76 decisions 3 and 4).
 */
enum class RelayedResource(
    val timeout: Duration,
    val keptHeaders: List<String>,
) {
    DATA(timeout = 10.seconds, keptHeaders = emptyList()),
    IMAGE(
        timeout = 30.seconds,
        keptHeaders = listOf(HttpHeaders.CacheControl, HttpHeaders.ETag, HttpHeaders.LastModified),
    ),
}
