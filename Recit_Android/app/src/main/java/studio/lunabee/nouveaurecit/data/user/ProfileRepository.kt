package studio.lunabee.nouveaurecit.data.user

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.NetworkError
import studio.lunabee.nouveaurecit.network.dto.GravatarDto
import studio.lunabee.nouveaurecit.network.dto.OkStatusDto
import java.io.File
import java.io.IOException

/**
 * `UserModel+Profile` (iOS feature 0055): writing the public half of the account — picture, name, bio,
 * position — from « Modifier le profil ». Server first, like « Modifier l'édition »: the form stays open
 * until the server has agreed, and my user takes each value only once it has ([store]).
 *
 * Every `PUT /api/user` goes through [pacer], the one the container shares with whatever else writes the
 * account.
 */
class ProfileRepository(
    private val api: ApiService,
    private val publicClient: OkHttpClient,
    private val pacer: RequestPacer,
    private val store: MyProfileStore,
) {
    /**
     * Sends [changes] one by one, in order, and writes each onto my user as it lands.
     *
     * Stops at the first refusal and throws it as a [ProfileSaveFailure] carrying what had already gone
     * through: there is no transaction on the server's side, so the caller keeps those and offers to send
     * the rest.
     */
    suspend fun saveProfile(changes: List<ProfileChange>) {
        val landed: MutableList<ProfileChange> = mutableListOf()
        for (change in changes) {
            try {
                write(change)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                throw ProfileSaveFailure(refused = change.kind, landed = landed.toList(), cause = error)
            }
            landed += change
        }
    }

    /** One `PUT /api/user`, in its slot. */
    suspend fun updateUserAttribute(update: UserAttributeUpdate) {
        pacer.run { api.send<UserAttributeUpdate, OkStatusDto>(USER_PATH, method = "PUT", body = update) }
    }

    /**
     * The account's Gravatar, as bytes ready to be reduced and uploaded like any picture, or `null` when its
     * address has none — the url the server builds answers `404` then (`?d=404`).
     *
     * Downloaded rather than handed to the server as a url: the form shows the picture before it is saved,
     * and saving it is then the same upload as a photograph's. The download goes to gravatar.com, which
     * needs nothing of ours, hence the client without cookies (ADR 0008).
     */
    suspend fun gravatarImage(): ByteArray? {
        val answer: GravatarDto = api.get(GRAVATAR_PATH)
        val url: HttpUrl = answer.url.toHttpUrlOrNull() ?: return null
        return withContext(Dispatchers.IO) {
            try {
                publicClient.newCall(Request.Builder().url(url).get().build()).execute().use { response ->
                    if (response.code == 200) response.body.bytes() else null
                }
            } catch (error: IOException) {
                throw NetworkError.Transport(error)
            }
        }
    }

    private suspend fun write(change: ProfileChange) {
        when (change) {
            is ProfileChange.Picture -> {
                // Uploaded first and named by the path the server files it under, `/img/users/<hash>` — the
                // only shape `picture` accepts. `null` takes it away.
                val path: String? = change.path?.let { upload(readPicture(it)) }
                updateUserAttribute(UserAttributeUpdate.of("picture", path))
                store.updateMyUser { it.copy(avatarUrl = ImageUrl.absolute(path)) }
            }
            is ProfileChange.Username -> {
                updateUserAttribute(UserAttributeUpdate.of("username", change.value))
                store.updateMyUser { it.copy(username = change.value) }
            }
            is ProfileChange.Bio -> {
                updateUserAttribute(UserAttributeUpdate.of("bio", change.value))
                store.updateMyUser { it.copy(bio = change.value) }
            }
            is ProfileChange.Position -> {
                updateUserAttribute(UserAttributeUpdate.of("position", change.coordinates))
                store.updateMyUser { it.copy(latitude = change.coordinates?.latitude, longitude = change.coordinates?.longitude) }
            }
        }
    }

    /** `POST /api/images/upload?container=users`: the server answers `{ <field>: "/img/users/<hash>" }`. */
    private suspend fun upload(bytes: ByteArray): String = api.upload(
        path = UPLOAD_PATH,
        query = listOf("container" to "users"),
        fieldName = PICTURE_FIELD,
        fileName = "avatar.jpg",
        bytes = bytes,
    )[PICTURE_FIELD] ?: throw NetworkError.BadResponse()

    private suspend fun readPicture(path: String): ByteArray = withContext(Dispatchers.IO) {
        File(path).takeIf(File::exists)?.readBytes() ?: throw NetworkError.BadResponse()
    }

    private companion object {
        const val USER_PATH: String = "/api/user"
        const val UPLOAD_PATH: String = "/api/images/upload"
        const val GRAVATAR_PATH: String = "/api/images/gravatar"
        const val PICTURE_FIELD: String = "avatar"
    }
}
