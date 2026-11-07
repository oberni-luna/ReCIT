package studio.lunabee.exlibris.backend.images

import kotlin.random.Random

/** Bytes the backend takes for a JPEG: it reads the signature, never decodes. Random, so each test has its own. */
object TestImages {
    private const val BODY_LENGTH: Int = 256

    fun jpeg(): ByteArray =
        byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte()) +
            Random.nextBytes(BODY_LENGTH) +
            byteArrayOf(0xFF.toByte(), 0xD9.toByte())
}
