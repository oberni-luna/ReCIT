package studio.lunabee.exlibris.backend.images

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.security.MessageDigest

/**
 * Images uploaded, served and released, and the Gravatar address. A file is named by the SHA-1 of its bytes,
 * the 40 hexadecimal characters inventaire.io's `/img/users/<hash>` paths carry.
 */
class ImagesService(
    private val store: ImageStore,
    private val repository: ImagesRepository,
) {
    /** `POST /api/images/upload`: each file's path, by the form field it came in, as inventaire.io's `indexUrlById`. */
    suspend fun upload(
        userId: String,
        containerParameter: String,
        files: List<UploadedFile>,
    ): Map<String, String> {
        val container: ImageContainer = container(containerParameter)
        val refusal: ApiException? =
            when {
                repository.email(userId) == null -> ApiException.unauthorized()

                files.isEmpty() -> ApiException(HttpStatusCode.BadRequest, "no file provided")

                files.any {
                    ImageFormat.of(
                        it.bytes,
                    ) == null
                } -> ApiException(HttpStatusCode.BadRequest, "invalid image")

                else -> null
            }
        refusal?.let { throw it }
        return files.associate { file ->
            val hash: String = sha1(file.bytes)
            store.put(container, hash, file.bytes)
            file.fieldName to container.path(hash)
        }
    }

    /** `GET /img/<container>/<hash>`; `null` when there is no such image. */
    suspend fun image(
        container: ImageContainer,
        hash: String,
    ): StoredImage? =
        store.read(container, hash)?.let { bytes ->
            ImageFormat.of(bytes)?.let { StoredImage(bytes, it.contentType) }
        }

    /**
     * Deletes the file at [path] once no account or group points at it any more: a picture replaced, an account
     * deleted, a group ended.
     */
    suspend fun releasePicture(path: String) {
        val container: ImageContainer = ImageContainer.ofPath(path) ?: return
        val hash: String = path.removePrefix(container.path(""))
        if (HASH_PATTERN.matches(hash) && !repository.isPicture(container, path)) {
            store.delete(container, hash)
        }
    }

    /**
     * inventaire.io's `/api/images/gravatar`, with the SHA-256 Gravatar now asks for (#71 decision 6) where
     * inventaire.io still sends an MD5: `d=404` so that an address without a Gravatar answers nothing.
     */
    suspend fun gravatarUrl(userId: String): GravatarUrl {
        val email: String = repository.email(userId) ?: throw ApiException.unauthorized()
        val hash: String =
            MessageDigest
                .getInstance("SHA-256")
                .digest(email.trim().lowercase().toByteArray())
                .toHexString()
        return GravatarUrl("https://gravatar.com/avatar/$hash?d=404&s=$GRAVATAR_SIZE")
    }

    private fun container(parameter: String): ImageContainer =
        ImageContainer.of(parameter) ?: throw if (parameter in ImageContainer.uploadable) {
            ApiException.notImplemented()
        } else {
            ApiException(
                HttpStatusCode.BadRequest,
                "invalid container: $parameter (possible values: ${ImageContainer.uploadable.joinToString()})",
            )
        }

    private fun sha1(bytes: ByteArray): String = MessageDigest.getInstance("SHA-1").digest(bytes).toHexString()

    companion object {
        /** What `/img/<container>/<hash>` accepts, and nothing a path could be climbed out of with. */
        val HASH_PATTERN: Regex = Regex("^[0-9a-f]{40}$")

        private const val GRAVATAR_SIZE: Int = 500
    }
}
