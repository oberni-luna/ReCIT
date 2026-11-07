package studio.lunabee.exlibris.backend.auth

import io.ktor.http.HttpStatusCode
import studio.lunabee.exlibris.backend.plugins.ApiException
import java.time.Clock

/**
 * The links e-mailed to an account — address confirmation, password reset — from asking for one to opening it.
 * A link opens once and for [TokenPurpose.lifetime]; asking again replaces the previous one.
 */
class AccountLinkService(
    private val repository: AuthRepository,
    private val passwordHasher: PasswordHasher,
    private val mails: AccountMails,
    private val mailsByAddress: AttemptLimiter,
    private val clock: Clock,
) {
    /** Throws `MessagingException` when the mail server refuses. */
    suspend fun sendConfirmation(account: Account) {
        mails.sendConfirmation(account, issueToken(account, TokenPurpose.EMAIL_CONFIRMATION))
    }

    /** Mails the link confirming the address [userId] just moved to (`PUT /api/user`). */
    suspend fun sendAddressConfirmation(userId: String) {
        repository.findById(userId)?.let { sendConfirmation(it) }
    }

    /** Mails the confirmation link again, to the signed-in user. */
    suspend fun requestEmailConfirmation(userId: String) {
        val account: Account =
            repository.findById(userId) ?: throw ApiException.unauthorized()
        val refusal: ApiException? =
            if (account.isEmailValidated) {
                ApiException(HttpStatusCode.BadRequest, "email was already validated")
            } else {
                limitRefusal(TokenPurpose.EMAIL_CONFIRMATION, account.email)
            }
        refusal?.let { throw it }
        sendConfirmation(account)
    }

    /**
     * Mails a reset link. An unknown address answers `400 email not found`, as inventaire.io does; the apps show
     * the same confirmation either way (`PasswordResetOutcome`).
     */
    suspend fun requestPasswordReset(email: String) {
        (AccountRules.emailRefusal(email) ?: limitRefusal(TokenPurpose.PASSWORD_RESET, email))?.let { throw it }
        val account: Account =
            repository.findByEmail(email) ?: throw ApiException(HttpStatusCode.BadRequest, "email not found")
        mails.sendPasswordReset(account, issueToken(account, TokenPurpose.PASSWORD_RESET))
    }

    /** The account a confirmation link confirmed, or `null` when it opens nothing: unknown, spent or expired. */
    suspend fun confirmEmail(token: String): Account? =
        repository.confirmEmail(AccountToken.hash(token), clock.millis())

    /** The account a reset link would change, the link left unspent: what the form is shown for. */
    suspend fun passwordResetAccount(token: String): Account? =
        repository.findTokenAccount(AccountToken.hash(token), TokenPurpose.PASSWORD_RESET, clock.millis())

    /** The form's answer: the password set and the link spent, or why not. */
    suspend fun resetPassword(
        token: String,
        password: String,
        confirmation: String,
    ): PasswordReset =
        when {
            password != confirmation -> {
                PasswordReset.MISMATCH
            }

            !AccountRules.isPassword(password) -> {
                PasswordReset.INVALID_PASSWORD
            }

            repository.resetPassword(
                AccountToken.hash(token),
                passwordHasher.hash(password),
                clock.millis(),
            ) == null -> {
                PasswordReset.INVALID_LINK
            }

            else -> {
                PasswordReset.DONE
            }
        }

    private suspend fun issueToken(
        account: Account,
        purpose: TokenPurpose,
    ): String {
        val token: String = AccountToken.generate()
        repository.replaceToken(
            account.id,
            purpose,
            AccountToken.hash(token),
            clock.millis() + purpose.lifetime.toMillis(),
        )
        return token
    }

    /** Three an hour per address and per kind of link (#70 decision 9). */
    private fun limitRefusal(
        purpose: TokenPurpose,
        email: String,
    ): ApiException? =
        if (mailsByAddress.tryAcquire(
                "${purpose.storedName}:${email.lowercase()}",
            )
        ) {
            null
        } else {
            ApiException.tooManyRequests()
        }
}
