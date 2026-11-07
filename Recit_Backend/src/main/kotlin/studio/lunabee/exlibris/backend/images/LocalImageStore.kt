package studio.lunabee.exlibris.backend.images

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/** [ImageStore] in a directory, `<directory>/<container>/<hash>`: a Docker volume in Compose, `data/images` locally. */
class LocalImageStore(
    private val directory: Path,
) : ImageStore {
    override suspend fun put(
        container: ImageContainer,
        hash: String,
        bytes: ByteArray,
    ) {
        withContext(Dispatchers.IO) {
            val file: Path = file(container, hash)
            if (Files.notExists(file)) {
                Files.createDirectories(file.parent)
                // Written aside then moved, so that a reader never meets half a file.
                val partial: Path = Files.createTempFile(file.parent, hash, ".partial")
                Files.write(partial, bytes)
                Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
            }
        }
    }

    override suspend fun read(
        container: ImageContainer,
        hash: String,
    ): ByteArray? =
        withContext(Dispatchers.IO) {
            file(container, hash).takeIf(Files::isRegularFile)?.let(Files::readAllBytes)
        }

    override suspend fun delete(
        container: ImageContainer,
        hash: String,
    ) {
        withContext(Dispatchers.IO) { Files.deleteIfExists(file(container, hash)) }
    }

    private fun file(
        container: ImageContainer,
        hash: String,
    ): Path = directory.resolve(container.parameter).resolve(hash)
}
