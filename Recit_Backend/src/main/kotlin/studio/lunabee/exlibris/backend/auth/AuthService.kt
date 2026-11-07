package studio.lunabee.exlibris.backend.auth

import io.ktor.http.HttpStatusCode
import jakarta.mail.MessagingException
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.DocumentId
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock

/**
 * inventaire.io's `/api/auth/…` controllers, refusing in the order and the words they do: the shape of each
 * parameter first, then what the database says. The apps read those words (`AuthFailure`, `FieldAvailability`,
 * `PasswordChangeFailure`), so they are kept to the letter.
 */
class AuthService(
    private val repository: AuthRepository,
    private val passwordHasher: PasswordHasher,
    private val links: AccountLinkService,
    /** Five attempts a minute per username or address (#70 decision 9), on top of the IP's ten. */
    private val loginByIdentifier: AttemptLimiter,
    private val clock: Clock,
) {
    /**
     * Creates the account and mails its confirmation link; returns its id, for the session signing up opens.
     * An unconfirmed address blocks nothing, as on inventaire.io.
     */
    suspend fun signup(
        username: String,
        email: String,
        password: String,
        language: String,
    ): String {
        val name: String = AccountRules.normalizeUsername(username)
        val refusal: ApiException? =
            AccountRules.usernameRefusal(name)
                ?: AccountRules.emailRefusal(email)
                ?: AccountRules.passwordRefusal("password", password)
                ?: takenRefusal(AccountField.USERNAME, name)
                ?: takenRefusal(AccountField.EMAIL, email)
        refusal?.let { throw it }

        val account: Account =
            Account(
                id = DocumentId.new(),
                username = name,
                email = email,
                passwordHash = passwordHasher.hash(password),
                language = language,
                isEmailValidated = false,
            )
        if (!repository.insert(account, created = clock.millis())) {
            throw takenRefusal(AccountField.USERNAME, name) ?: takenRefusal(AccountField.EMAIL, email) ?: conflict()
        }
        try {
            links.sendConfirmation(account)
        } catch (error: MessagingException) {
            // The account exists whatever the mail server says: its confirmation can be asked for again.
            logger.warn("Confirmation e-mail not sent to account {}: {}", account.id, error.message)
        }
        return account.id
    }

    /** The account [identifier] — a username or an address — and [password] open; refused with a `401` otherwise. */
    suspend fun login(
        identifier: String,
        password: String,
    ): String {
        val login: String = AccountRules.normalizeUsername(identifier)
        val refusal: ApiException? =
            AccountRules.loginRefusal(login)
                ?: AccountRules.passwordRefusal("password", password)
                ?: if (loginByIdentifier.tryAcquire(login.lowercase())) null else ApiException.tooManyRequests()
        refusal?.let { throw it }

        return findByLogin(login)?.takeIf { passwordHasher.verify(password, it.passwordHash) }?.id
            ?: throw ApiException(HttpStatusCode.Unauthorized, "invalid_username_or_password")
    }

    /**
     * "Valid **and** free", as `/auth/username-availability` and `/auth/email-availability` answer; returns
     * [value] as it was read.
     */
    suspend fun checkAvailability(
        field: AccountField,
        value: String,
    ): String {
        val normalized: String = if (field == AccountField.USERNAME) AccountRules.normalizeUsername(value) else value
        val shapeRefusal: ApiException? =
            when (field) {
                AccountField.USERNAME -> AccountRules.usernameRefusal(normalized)
                AccountField.EMAIL -> AccountRules.emailRefusal(normalized)
            }
        (shapeRefusal ?: takenRefusal(field, normalized))?.let { throw it }
        return normalized
    }

    /** `PUT /api/auth/password`: only the hash changes, so every session stays open. */
    suspend fun changePassword(
        userId: String,
        currentPassword: String,
        newPassword: String,
    ) {
        val account: Account = repository.findById(userId) ?: throw ApiException.unauthorized()
        (AccountRules.passwordRefusal("new-password", newPassword) ?: currentPasswordRefusal(account, currentPassword))
            ?.let { throw it }
        repository.updatePasswordHash(account.id, passwordHasher.hash(newPassword))
    }

    /** inventaire.io's `findUserByUsernameOrEmail`: an address is looked up as one, anything else as a username. */
    private suspend fun findByLogin(login: String): Account? =
        if (AccountRules.isEmail(login)) repository.findByEmail(login) else repository.findByUsername(login)

    /** `PasswordChangeFailure` reads `old-password` in the answer: the field to fix is the first one. */
    private suspend fun currentPasswordRefusal(
        account: Account,
        password: String,
    ): ApiException? =
        if (AccountRules.isPassword(password) && passwordHasher.verify(password, account.passwordHash)) {
            null
        } else {
            ApiException(HttpStatusCode.BadRequest, "invalid old-password")
        }

    private suspend fun takenRefusal(
        field: AccountField,
        value: String,
    ): ApiException? {
        val account: Account? =
            when (field) {
                AccountField.USERNAME -> repository.findByUsername(value)
                AccountField.EMAIL -> repository.findByEmail(value)
            }
        return account?.let { ApiException(HttpStatusCode.BadRequest, "this ${field.parameter} is already used") }
    }

    private companion object {
        val logger: Logger = LoggerFactory.getLogger(AuthService::class.java)

        fun conflict(): ApiException = ApiException(HttpStatusCode.Conflict, "account conflict")
    }
}
