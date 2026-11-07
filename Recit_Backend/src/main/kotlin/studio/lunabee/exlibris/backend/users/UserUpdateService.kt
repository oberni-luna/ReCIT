package studio.lunabee.exlibris.backend.users

import io.ktor.http.HttpStatusCode
import jakarta.mail.MessagingException
import kotlinx.serialization.json.JsonElement
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.auth.AccountLinkService
import studio.lunabee.exlibris.backend.auth.AccountRules
import studio.lunabee.exlibris.backend.auth.AttemptLimiter
import studio.lunabee.exlibris.backend.images.ImagesService
import studio.lunabee.exlibris.backend.plugins.ApiException

/**
 * `PUT /api/user`, one attribute per call, as inventaire.io's `controllers/user/update.ts`: every attribute the
 * apps send is stored and served back. A username is renamed under signup's rules, an address goes back to
 * unconfirmed and gets its link mailed; the notification settings and `fediversable` change nothing else (#62).
 */
class UserUpdateService(
    private val repository: UsersRepository,
    private val links: AccountLinkService,
    private val images: ImagesService,
    /** Each change of address mails a link to it: three an hour per account, so it cannot be used to spam. */
    private val addressChanges: AttemptLimiter,
) {
    suspend fun update(
        userId: String,
        attribute: String,
        value: JsonElement?,
    ) {
        val user: UserRecord = currentUser(userId)
        val update: ProfileUpdate = normalized(ProfileUpdateReader.read(attribute, value))
        val refusal: ApiException? =
            when {
                !update.changes(user) -> ApiException(HttpStatusCode.BadRequest, "already up-to-date")
                update is ProfileUpdate.Username -> usernameRefusal(user, update.value)
                update is ProfileUpdate.Email -> emailRefusal(user, update.value)
                else -> null
            }
        refusal?.let { throw it }
        if (!repository.apply(userId, update)) throw takenRefusal(update)
        afterUpdate(user, update)
    }

    /** A session naming an account that is gone is refused like no session. */
    private suspend fun currentUser(userId: String): UserRecord =
        repository.findById(userId) ?: throw ApiException.unauthorized()

    /** inventaire.io's `userFormatters`: a username normalized as at signup. */
    private fun normalized(update: ProfileUpdate): ProfileUpdate =
        if (update is ProfileUpdate.Username) {
            ProfileUpdate.Username(
                AccountRules.normalizeUsername(update.value),
            )
        } else {
            update
        }

    /** Changing only the case of one's own username needs no check, as on inventaire.io. */
    private suspend fun usernameRefusal(
        user: UserRecord,
        username: String,
    ): ApiException? =
        if (username.equals(user.username, ignoreCase = true)) {
            null
        } else {
            AccountRules.usernameRefusal(username)
                ?: takenRefusal(
                    ProfileUpdate.Username(username),
                ).takeIf { repository.isUsernameTaken(username, user.id) }
        }

    private suspend fun emailRefusal(
        user: UserRecord,
        email: String,
    ): ApiException? =
        AccountRules.emailRefusal(email)
            ?: takenRefusal(ProfileUpdate.Email(email)).takeIf { repository.isEmailTaken(email, user.id) }
            ?: ApiException.tooManyRequests().takeUnless { addressChanges.tryAcquire(user.id) }

    private suspend fun afterUpdate(
        user: UserRecord,
        update: ProfileUpdate,
    ) {
        when (update) {
            is ProfileUpdate.Email -> {
                try {
                    links.sendAddressConfirmation(user.id)
                } catch (error: MessagingException) {
                    // The address is changed whatever the mail server says: its confirmation can be asked for again.
                    logger.warn("Confirmation e-mail not sent to account {}: {}", user.id, error.message)
                }
            }

            is ProfileUpdate.Picture -> {
                user.picture?.let { images.releaseUserPicture(it) }
            }

            else -> {
                Unit
            }
        }
    }

    private companion object {
        val logger: Logger = LoggerFactory.getLogger(UserUpdateService::class.java)

        /** The words of inventaire.io's `checkAvailability`, which signup answers too. */
        fun takenRefusal(update: ProfileUpdate): ApiException {
            val field: String = if (update is ProfileUpdate.Email) "email" else "username"
            return ApiException(HttpStatusCode.BadRequest, "this $field is already used")
        }
    }
}
