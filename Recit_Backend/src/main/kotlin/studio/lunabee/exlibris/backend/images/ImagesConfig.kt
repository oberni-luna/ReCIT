package studio.lunabee.exlibris.backend.images

import io.ktor.server.config.ApplicationConfig
import java.nio.file.Path

data class ImagesConfig(
    /** Where [LocalImageStore] files the images, relative to the working directory unless absolute. */
    val directory: Path,
) {
    companion object {
        fun from(config: ApplicationConfig): ImagesConfig =
            ImagesConfig(directory = Path.of(config.property("images.directory").getString()))
    }
}
