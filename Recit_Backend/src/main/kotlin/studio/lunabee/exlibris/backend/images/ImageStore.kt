package studio.lunabee.exlibris.backend.images

/**
 * Where the images' bytes live, by container and content hash (#62 decision 15). On disk for one server
 * ([LocalImageStore]); S3 would be a second implementation, if there is ever more than one.
 */
interface ImageStore {
    /** Files [bytes] under [hash]; filing the same image twice keeps one copy. */
    suspend fun put(
        container: ImageContainer,
        hash: String,
        bytes: ByteArray,
    )

    suspend fun read(
        container: ImageContainer,
        hash: String,
    ): ByteArray?

    /** Nothing happens when there is no such image. */
    suspend fun delete(
        container: ImageContainer,
        hash: String,
    )
}
