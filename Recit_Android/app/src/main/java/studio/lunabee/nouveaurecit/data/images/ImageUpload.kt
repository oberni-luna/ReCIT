package studio.lunabee.nouveaurecit.data.images

import studio.lunabee.nouveaurecit.network.ApiService

/** `POST /api/images/upload`: one picture sent to inventaire.io, the one request of the app that is not JSON. */
class ImageUpload(private val api: ApiService) {
    /** Sends [bytes] into [container], and answers the path the server filed them under — `null` when it names none. */
    suspend fun upload(bytes: ByteArray, container: ImageContainer): String? = api.upload(
        path = "/api/images/upload",
        query = listOf("container" to container.value),
        fieldName = container.fieldName,
        fileName = container.fileName,
        bytes = bytes,
    )[container.fieldName]
}
