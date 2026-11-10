package studio.lunabee.nouveaurecit.data.groups

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import studio.lunabee.nouveaurecit.data.images.ImageContainer
import studio.lunabee.nouveaurecit.data.images.ImageUpload
import studio.lunabee.nouveaurecit.network.NetworkError
import java.io.File

/**
 * `GroupModel.uploadedPicturePath`: a group's photo sent to inventaire.io, the first half of
 * `GroupRepository.updatePicture`.
 */
class GroupPictureUpload(private val images: ImageUpload) {
    /** The photo read from the cache at [localPath], sent into `groups`: the path it was filed under, `/img/groups/<hash>`. */
    suspend fun upload(localPath: String): String {
        val bytes: ByteArray = withContext(Dispatchers.IO) { File(localPath).readBytes() }
        return images.upload(bytes, ImageContainer.Groups) ?: throw NetworkError.BadResponse()
    }
}
