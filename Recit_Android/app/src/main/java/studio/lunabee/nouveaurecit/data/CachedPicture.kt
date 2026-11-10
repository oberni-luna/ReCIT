package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/** A picture reduced into the app's cache, read back as the bytes an upload sends. */
object CachedPicture {
    /** The file's bytes; `null` if the cache lost the file. */
    suspend fun bytes(path: String): ByteArray? = withContext(Dispatchers.IO) {
        File(path).takeIf(File::exists)?.readBytes()
    }
}
