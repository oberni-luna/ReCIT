package studio.lunabee.nouveaurecit.data.groups

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.NetworkError
import java.io.File

/**
 * `GroupModel.uploadedPicturePath`: a group's photo sent to inventaire.io, the first half of
 * `GroupRepository.updatePicture`.
 */
class GroupPictureUpload(private val api: ApiService) {
    /**
     * `POST /api/images/upload` into `groups`, the photo read from the cache at [localPath]. The server
     * keys its answer by the form field's name, and answers the path it filed the picture under,
     * `/img/groups/<hash>`.
     */
    suspend fun path(localPath: String): String {
        val bytes: ByteArray = withContext(Dispatchers.IO) { File(localPath).readBytes() }
        val answer: Map<String, String> = api.upload(
            path = "/api/images/upload",
            query = listOf("container" to "groups"),
            fieldName = FIELD,
            fileName = "group.jpg",
            bytes = bytes,
        )
        return answer[FIELD] ?: throw NetworkError.BadResponse()
    }

    private companion object {
        /** The upload's form field, and so the key its answer is read back under. */
        const val FIELD: String = "picture"
    }
}
