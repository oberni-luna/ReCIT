package studio.lunabee.exlibris.backend.images

import io.ktor.http.ContentType

/** An image as `/img/…` serves it. */
class StoredImage(
    val bytes: ByteArray,
    val contentType: ContentType,
)
