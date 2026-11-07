package studio.lunabee.exlibris.backend.images

import io.ktor.http.ContentType

/**
 * The formats an upload may be, told by their first bytes: inventaire.io re-encodes whatever it receives, this
 * backend keeps the file as sent (no resizing in v1), so it accepts only what the apps send and serves it under
 * its own type, never as something a browser would run.
 */
enum class ImageFormat(
    val contentType: ContentType,
    private val signature: ByteArray,
    private val offset: Int = 0,
) {
    JPEG(ContentType.Image.JPEG, byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte())),
    PNG(ContentType.Image.PNG, byteArrayOf(0x89.toByte(), 'P'.code.toByte(), 'N'.code.toByte(), 'G'.code.toByte())),
    WEBP(ContentType("image", "webp"), "WEBP".toByteArray(), offset = 8),
    ;

    private fun matches(bytes: ByteArray): Boolean =
        bytes.size >= offset + signature.size &&
            signature.indices.all { bytes[offset + it] == signature[it] }

    companion object {
        fun of(bytes: ByteArray): ImageFormat? = entries.firstOrNull { it.matches(bytes) }
    }
}
