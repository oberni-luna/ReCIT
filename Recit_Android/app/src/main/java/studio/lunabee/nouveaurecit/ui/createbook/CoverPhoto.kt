package studio.lunabee.nouveaurecit.ui.createbook

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.net.Uri
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * `CoverCaptureView.jpegData` (feature 0020): the photograph of a cover, reduced to something worth
 * sending. Files live in the cache, under the one directory `res/xml/cover_paths.xml` shares with the
 * camera app.
 */
object CoverPhoto {
    /** A cover is shown at a few hundred dp at most, and inventaire.io resizes on its side too. */
    private const val MAX_DIMENSION: Int = 1600

    /** High enough that a title stays readable, low enough for a bookshop's Wi-Fi. */
    private const val JPEG_QUALITY: Int = 80

    /** Where the camera app writes the full-size photograph, before it is reduced. */
    fun newCaptureFile(context: Context): File = File(coverDirectory(context), "capture-${System.currentTimeMillis()}.jpg")

    fun shareableUri(context: Context, file: File): Uri = FileProvider.getUriForFile(context, "${context.packageName}.covers", file)

    /**
     * Reads [source] — `ImageDecoder` turns it upright from its EXIF orientation — scales its longest edge
     * down to [MAX_DIMENSION] and writes it as a JPEG. Answers the reduced file's path, or `null` when the
     * image cannot be read: the form then simply has no cover, which it never needed.
     */
    suspend fun reduce(context: Context, source: Uri): String? = withContext(Dispatchers.IO) {
        runCatching {
            val decoded: Bitmap = ImageDecoder.decodeBitmap(ImageDecoder.createSource(context.contentResolver, source)) { decoder, info, _ ->
                // In memory the encoder can read: a hardware bitmap's pixels are out of its reach.
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                val longest: Int = max(info.size.width, info.size.height)
                if (longest > MAX_DIMENSION) {
                    val scale: Float = MAX_DIMENSION.toFloat() / longest
                    decoder.setTargetSize((info.size.width * scale).roundToInt(), (info.size.height * scale).roundToInt())
                }
            }
            val output = File(coverDirectory(context), "cover-${System.currentTimeMillis()}.jpg")
            output.outputStream().use { decoded.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it) }
            output.absolutePath
        }.getOrNull()
    }

    /** The reduced photograph's bytes, as they go to the upload; `null` if the cache lost the file. */
    suspend fun bytes(path: String): ByteArray? = withContext(Dispatchers.IO) {
        File(path).takeIf(File::exists)?.readBytes()
    }

    private fun coverDirectory(context: Context): File = File(context.cacheDir, "covers").apply { mkdirs() }
}
